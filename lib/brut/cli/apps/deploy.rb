require "brut/cli"
require "fileutils"
require "pathname"

class Brut::CLI::Apps::Deploy < Brut::CLI::Commands::BaseCommand
  def name = "deploy"

  def description = "Deploy your Brut-powered app to production"

  def default_rack_env = nil

  class Heroku < Brut::CLI::Commands::BaseCommand
    def description = "Deploy to Heroku using container-based deployment"
    def opts = [
      [ "--[no-]deploy", "If true, actually deploy the pushed images (default true)" ],
      [ "--skip-checks", "If true, skip pre-build checks" ],
    ]

    def default_rack_env = "development"

    def run
      options.set_default(:deploy, true)
      puts "Logging in to Heroku Container Registry"
      command = %{heroku container:login}
      system!(command)
      execute_result = Brut::CLI::ExecuteResult.new do
        delegate_to_command(
          Brut::CLI::Apps::Deploy::Build.new(
            push: options.deploy? ? "registry.heroku.com/#{Brut.container.app_id}/%{name}": false
          )
        )
      end
      if execute_result.failed?
        puts theme.error.render("Build failed.")
        return execute_result.exit_status do |error_message|
          puts theme.error.render("Error message from build: #{error_message}")
        end
      end
      names = []
      app_docker_files = AppDockerImages.new(
        project_root: Brut.container.project_root,
        organization: Brut.container.app_organization,
        app_id: Brut.container.app_id,
        short_version: "NA"
      )
      app_docker_files.each do |name:, cmd:, dockerfile:|
        names << name
      end

      deploy_command = "heroku container:release #{names.join(' ')} -a #{Brut.container.app_id}"
      if options.deploy?
        puts "Deploying images to Heroku"
        system!(deploy_command)
      else
        puts "Not deploying.  To deploy the images just pushed:"
        puts ""
        puts "  #{deploy_command}"
      end
    end
  end

  class AppDockerImages
    attr_reader :docker_config_filename, :platform
    def initialize(organization:, app_id:, project_root:, short_version:)
      @docker_config_filename = project_root / "deploy" / "docker_config"
      require_relative @docker_config_filename
      if ! defined?(DockerConfig)
        raise "#{@docker_config_filename} did not define the constant `DockerConfig` - it must to provide the configuration values to this script"
      end

      docker_config = DockerConfig.new
      @platform = docker_config.platform

      additional_images = (docker_config.additional_images || {}).map { |name,config|
        cmd = config.fetch(:cmd)
        image_name = %{#{Brut.container.app_organization}/#{Brut.container.app_id}:#{short_version}-#{name}}
        [
          name,
          {
            cmd:,
            image_name:,
            dockerfile: "deploy/Dockerfile.#{name}",
          },
        ]
      }.to_h

      @images = {
        "web" => {
          cmd: "bin/run",
          image_name: %{#{Brut.container.app_organization}/#{app_id}:#{short_version}-web},
          dockerfile: "deploy/Dockerfile.web",
        },
        "release" => {
          cmd: "bin/release",
          image_name: %{#{Brut.container.app_organization}/#{app_id}:#{short_version}-release},
          dockerfile: "deploy/Dockerfile.release",
        },
      }.merge(additional_images)
    end

    def each(&block)
      if block.parameters.any? { it[0] != :keyreq }
        raise "block for #{self.class}#each must only contain required keyword parameters"
      end
      @images.each do |name,metadata|
        args = {}
        block.parameters.each do |(_,param)|
          if param == :name
            args[:name] = name
          else
            args[param] = metadata.fetch(param)
          end
        end
        block.(**args)
      end
    end
  end

  class Build < Brut::CLI::Commands::BaseCommand
    def description      = Docker.new.description
    def opts             = Docker.new.opts
    def default_rack_env = Docker.new.default_rack_env

    def initialize(push: false)
      @push = push
    end
    def run
      delegate_to_command(Docker.new(push: @push))
    end

    def commands = []

    class Docker < Brut::CLI::Commands::BaseCommand
      def description = "Build a series of Docker images from a template Dockerfile"
      def opts = [
        [ "--platform=PLATFORM","Override default platform. Can be any Docker platform." ],
        [ "--dry-run", "Only show what would happen, don't actually do anything" ],
        [ "--skip-checks", "If true, skip pre-build checks (default )" ],
      ]
      def default_rack_env = "development"

      def initialize(push: false)
        @push = push
      end

      def run
        if !options.skip_checks?
          execute_result = Brut::CLI::ExecuteResult.new do
            delegate_to_command(Brut::CLI::Apps::Deploy::Check.new)
          end
          if execute_result.failed?
            puts theme.error.render("Pre-build checks failed.")
            return execute_result.exit_status do |error_message|
              puts theme.error.render("Error message from checks: #{error_message}")
            end
          end
        end
        version = ""
        git_guess = %{git rev-parse HEAD}
        system!(git_guess) do |output|
          version << output
        end
        version.strip!.chomp!
        if version == ""
          error "Attempt to use git via command '#{git_guess}' to figure out the version failed"
          return 1
        end
        short_version = version[0..7]
        app_docker_files = AppDockerImages.new(
          project_root: Brut.container.project_root,
          organization: Brut.container.app_organization,
          app_id: Brut.container.app_id,
          short_version:
        )
        options.set_default(:platform, app_docker_files.platform || "linux/amd64")

        FileUtils.chdir Brut.container.project_root do

          puts
          puts theme.header.render("Generating Dockerfiles")
          puts
          rows = []
          app_docker_files.each do |name:, cmd:, dockerfile:|

            rows << [theme.subheader.render(name), theme.code.render(dockerfile), theme.code.render(cmd) ]

            if !options.dry_run?
              File.open(dockerfile,"w") do |file|
                file.puts "# DO NOT EDIT - THIS IS GENERATED"
                file.puts "# To make changes, modifiy deploy/Dockerfile and run #{$0}"
                file.puts File.read("deploy/Dockerfile")
                file.puts
                file.puts "# Added by #{$0}"
                file.puts %{CMD [ "bundle", "exec", "#{cmd}" ]}
              end
            end
          end
          table = Lipgloss::Table.new.headers(["Name", "Dockerfile", "CMD"]).
            rows(rows).
            style_func(rows: rows.length, columns: 3) { Lipgloss::Style.new.padding_right(1).padding_left(1) }
          puts table.render

          puts
          puts theme.header.render("Images")
          puts
          rows = []
          items = []
          push_or_load = @push ? "--push" : "--load"
          app_docker_files.each do |name:, image_name:, dockerfile:|
            if @push && @push.kind_of?(String)
              image_name = @push % { name: name }
            end
            rows << [ name, theme.code.render(image_name) ]
            command = %{docker buildx build --provenance=false --build-arg app_git_sha1=#{version} --file #{Brut.container.project_root}/#{dockerfile} --platform #{options.platform} #{push_or_load} --tag #{image_name} . 2>&1}
            items << theme.code.render(theme.wrap(command, first_indent: false, indent: 7, newline: " \\\n"))
            if !options.dry_run?
              puts theme.subheader.render("Building #{@push ? 'and pushing' : '' } '#{name}' image")
              system!(command)
            end
          end
          if options.dry_run?
            table = Lipgloss::Table.new.headers(["Name", "Image Name" ]).
              rows(rows).
              style_func(rows: rows.length, columns: 3) { Lipgloss::Style.new.padding_right(1).padding_left(1) }
            puts table.render
            puts
            puts theme.subheader.render("Commands:")
            puts
            puts Lipgloss::List.new.items(items).item_style(theme.code).render
          end
        end
      end
    end
  end

    class Check < Brut::CLI::Commands::BaseCommand

      def description = "Check that a deploy can be reasonably expected to succeed"

      def opts = Git.new.opts
      def run = delegate_to_command(Git.new)
      def commands = []

      class Git < Brut::CLI::Commands::BaseCommand
        def description = "Perform the check assuming Git is the version-control system"
        def opts = [
          [ "--[no-]check-branch", "If true, requires that you are on 'main' (default true)" ],
          [ "--[no-]check-changes", "If true, requires that you have committed all local changes (default true)" ],
          [ "--[no-]check-push", "If true, requires that you are in sync with origin/main (default true)" ],
        ]

        def run
          puts theme.header.render("Checking Git repo to see if changes have all been pushed to main")
          puts

          options.set_default(:check_branch,  true)
          options.set_default(:check_changes, true)
          options.set_default(:check_push,    true)

          checks = []

          branch = ""
          system!("git branch --show-current") do |output|
            branch << output
          end
          branch = branch.strip.chomp
          checks << [
            "Deploy from main",
          ]
          if branch != "main"
            checks.last << "Currently on #{theme.code.render(branch)}"
            checks.last << options.check_branch?
          end

          system!("git status") do |*| # reset local caches to account for Docker/host wierdness
            # ignore
          end
          local_changes = ""
          system!("git diff-index --name-only HEAD --") do |output|
            local_changes << output
          end
          checks << [
            "No un-committed changes",
          ]
          if local_changes.strip != ""
            items = local_changes.split(/\n/)
            list = Lipgloss::List.new.items(items).item_style(theme.error)
            checks.last << "Files not committed:\n#{list.render.strip}\n"
            checks.last << options.check_changes?
          end

          rev_list = ""
          system!("git rev-list --left-right --count origin/main...main") do |output|
            rev_list << output
          end
          remote_ahead, local_ahead = rev_list.strip.chomp.split(/\t/,2).map(&:to_i)
          checks << [
            "Pulled from origin",
          ]
          if remote_ahead != 0
            if remote_ahead == 1
              checks.last << "There is 1 commit in origin you don't have"
            else
              checks.last << "There are #{remote_ahead} commits in origin you don't have"
            end
            checks.last << options.check_push?
          end
          checks << [
            "Pushed to origin",
          ]

          if local_ahead != 0
            if local_ahead == 1
              checks.last << "There is 1 commit not pushed to origin"
            else
              checks.last << "There are #{local_ahead} commits not pushed to origin"
            end
            checks.last << options.check_push?
          end

          rows = []
          checks.each do |(check,status,error)|
            row = [ check ]
            if status
              if error
                row << theme.error.render("FAILED")
              else
                row << theme.warning.render("Ignored")
              end
              row << theme.error.render(status)
            else
              row << theme.success.render("OK")
              row << ""
            end
            rows << row
          end
          table = Lipgloss::Table.new.
            headers(["Check", "Result", "Details"]).
            rows(rows).
            style_func(rows: rows.length, columns: 3) { |row,column|
            if row == Lipgloss::Table::HEADER_ROW
              Lipgloss::Style.new.inherit(theme.header).padding_left(1).padding_right(1)
            elsif column == 0
              Lipgloss::Style.new.inherit(theme.subheader).padding_left(1).padding_right(1).padding_bottom(1)
            else
              Lipgloss::Style.new.inherit(theme.none).padding_left(1).padding_right(1).padding_bottom(1)
            end
          }
        puts table.render
        checks_failed = checks.count { |(_,status,_)| status }
        checks_failed_not_ignored = checks.count { |(_,status,error)| status && error }
        if checks_failed > 0
          if checks_failed_not_ignored > 0
            puts theme.error.render("#{checks_failed} checks failed - aborting")
            return 1
          else
            puts theme.warning.render("#{checks_failed} checks failed but ignored")
          end
        else
          puts theme.success.render("All checks passed")
        end

        0
      end
    end
  end
end
