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
      if delegate_to_command(Deploy::Build.new) != 0
        error "<== Build failed."
        return 1
      end
      options.set_default(:deploy, true)
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
      names = []
      puts "Logging in to Heroku Container Registry"
      command = %{heroku container:login}
      system!(command)
      app_docker_files.each do |name:, image_name:|
        heroku_image_name = "registry.heroku.com/#{Brut.container.app_id}/#{name}"
        puts "Tagging '#{image_name}' with '#{heroku_image_name}' for Heroku"
        command = %{docker tag #{image_name} #{heroku_image_name}}
        system!(command)
        docker_quiet_option = if options.log_level == "debug"
                                ""
                              else
                                "--quiet"
                              end
        begin
          puts "Pushing '#{heroku_image_name}'"
          command = %{docker push #{docker_quiet_option} #{heroku_image_name}}
          system!(command)
        rescue Brut::CLI::SystemExecError => ex
          error "Failed to push image '#{heroku_image_name}' to Heroku"
          if options.log_level != "debug"
            error "Could be you must re-authenticate to Heroku."
            error "Try re-running with --log-level=debug to see more details"
          end
          return 1
        end
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
    attr_reader :docker_config_filename
    def initialize(organization:, app_id:, project_root:, short_version:)
      @docker_config_filename = project_root / "deploy" / "docker_config"
      require_relative @docker_config_filename
      if ! defined?(DockerConfig)
        raise "#{@docker_config_filename} did not define the constant `DockerConfig` - it must to provide the configuration values to this script"
      end

      docker_config = DockerConfig.new

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
    def run              = delegate_to_command(Docker.new)

    def commands = []

    class Docker < Brut::CLI::Commands::BaseCommand
      def description = "Build a series of Docker images from a template Dockerfile"
      def opts = [
        [ "--platform=PLATFORM","Override default platform. Can be any Docker platform." ],
        [ "--dry-run", "Only show what would happen, don't actually do anything" ],
        [ "--skip-checks", "If true, skip pre-build checks (default )" ],
      ]
      def default_rack_env = "development"

      def run
        if !options.skip_checks?
          if delegate_to_command(Deploy::Check.new) != 0
            error "<== Pre-build checks failed."
            error "!!! Fix these issues or re-run with --skip-checks to proceed anyway."
            return 1
          end
        end
        options.set_default(:platform, "linux/amd64")
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

        short_version = version[0..7]
        app_docker_files = AppDockerImages.new(
          project_root: Brut.container.project_root,
          organization: Brut.container.app_organization,
          app_id: Brut.container.app_id,
          short_version:
        )

        FileUtils.chdir Brut.container.project_root do

          puts "Generating Dockerfiles"
          app_docker_files.each do |name:, cmd:, dockerfile:|

            puts "Creating '#{dockerfile}' for '#{name}' that will use command '#{cmd}'"

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

          puts "Building images"
          docker_quiet_option = if options.log_level == "debug"
                                  ""
                                else
                                  "--quiet"
                                end
          app_docker_files.each do |image_name:, dockerfile:|
            puts "Creating docker image with name '#{image_name}' and platform '#{options.platform}'"
            command = %{docker build #{docker_quiet_option} --build-arg app_git_sha1=#{version} --file #{Brut.container.project_root}/#{dockerfile} --platform #{options.platform} --tag #{image_name} .}
            if options.dry_run?
              puts "Would run '#{command}'"
            else
              system!(command)
            end
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
        puts "==> Checking Git repo to see if changes have all been pushed to main"
        checks_ignored = 0

        options.set_default(:check_branch,  true)
        options.set_default(:check_changes, true)
        options.set_default(:check_push,    true)

        branch = ""
        system!("git branch --show-current") do |output|
          branch << output
        end
        branch = branch.strip.chomp
        if branch != "main"
          error "<== You are not on the 'main' branch, but on '#{branch}'"
          if options.check_branch?
            error "!!! You may only deploy from main"
            return 1
          else
            checks_ignored += 1
            error "~~  Ignoring..."
          end
        end

        system!("git status") do |*| # reset local caches to account for Docker/host wierdness
          # ignore
        end
        local_changes = ""
        system!("git diff-index --name-only HEAD --") do |output|
          local_changes << output
        end
        if local_changes.strip != ""
          error "<== You have un-committed changes:"
          error
          local_changes.split(/\n/).each do |change|
            checks_ignored += 1
            error "  #{change}"
          end
          error
          if options.check_changes?
            error "!!! Commit or revert these, then push to origin"
            return 1
          else
            checks_ignored += 1
            error "~~  Ignoring..."
          end
        end

        rev_list = ""
        system!("git rev-list --left-right --count origin/main...main") do |output|
          rev_list << output
        end
        remote_ahead, local_ahead = rev_list.strip.chomp.split(/\t/,2).map(&:to_i)
        if remote_ahead != 0
          error "<== There are commits in origin you don't have."
          if options.check_push?
            error "!!! Pull those in, re-run bin/ci, THEN deploy"
            return 1
          else
            checks_ignored += 1
            error "~~  Ignoring..."
          end
        end

        if local_ahead != 0
          error "<== You have not pushed to origin."
          if options.check_push?
            error "!!! Push to origin before deploying"
            return 1
          else
            checks_ignored += 1
            error "~~  Ignoring..."
          end
        end
        if checks_ignored == 0
          puts "<== All checks passed"
        else
          puts "~~  #{checks_ignored} checks failed, but ignored"
        end

        0
      end
    end
  end
end
