require "brut/cli"

class Brut::CLI::Apps::Deploy < Brut::CLI::Commands::BaseCommand
  def description = "Deploy your Brut-powered app to production"

  def default_rack_env = nil

  class Heroku < Brut::CLI::Commands::BaseCommand
    def description = "Deploy to Heroku using container-based deployment"
    def run
      version = ""
      git_guess = %{git rev-parse HEAD}
      system!(git_guess) do |output|
        version << output
      end
      version.strip!.chomp!
      if version == ""
        stderr.puts "Attempt to use git via command '#{git_guess}' to figure out the version failed"
        return 1
      end
      short_version = version[0..7]
      app_docker_files = AppDockerImages.new(
        project_root: Brut.container.project_root,
        organization: Brut.container.organization,
        app_id: Brut.container.app_id,
        short_version:
      )
      #add  heroku_image_name: "registry.heroku.com/#{heroku_app_name}/web",
      #stdout.puts "Taggging images for Heroku"
      #images.each do |name,metadata|
      #  image_name        = metadata.fetch(:image_name)
      #  heroku_image_name = metadata.fetch(:heroku_image_name)
#
#        stdout.puts "Tagging '#{image_name}' with '#{heroku_image_name}' for Heroku"
#        command = %{docker tag #{image_name} #{heroku_image_name}}
#        system!(command)
#      end
#
#      if options.push?
#        stdout.puts "Pushing to Heroku Registry"
#        images.each do |name,metadata|
#          heroku_image_name = metadata.fetch(:heroku_image_name)
#
#          stdout.puts "Pushing '#{heroku_image_name}'"
#
#          command = %{docker push #{docker_quiet_option} #{heroku_image_name}}
#          system!(command)
#        end
#      else
#        stdout.puts "Not pushing images"
#      end
#
#      names = images.map(&:first).join(" ")
#      deploy_command = "heroku container:release #{names} -a #{heroku_app_name}"
#      if options.deploy?
#        stdout.puts "Deploying images to Heroku"
#        system!(deploy_command)
#      else
#        stdout.puts "Not deploying.  To deploy the images just pushed:"
#        stdout.puts ""
#        stdout.puts "  #{deploy_command}"
#      end
#    end
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

      additional_images = (docker_confir.additional_images || {}).map { |name,config|
        cmd = config.fetch(:cmd)
        image_name = %{#{app_organization}/#{app_id}:#{short_version}-#{name}}
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
          image_name: %{#{app_organization}/#{app_id}:#{short_version}-web},
          dockerfile: "deploy/Dockerfile.web",
        },
        "release" => {
          cmd: "bin/run",
          image_name: %{#{app_organization}/#{app_id}:#{short_version}-web},
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
        block.params.each do |(_,param)|
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
    def description = "Build artifacts for deployment"

    class Docker < Brut::CLI::Commands::BaseCommand
      def description = "Build a series of Docker images from a template Dockerfile"
      def opts = [
        [ "--platform=PLATFORM","Override default platform. Can be any Docker platform." ],
        [ "--dry-run", "Only show what would happen, don't actually do anything" ],
      ]

      def run
        version = ""
        git_guess = %{git rev-parse HEAD}
        system!(git_guess) do |output|
          version << output
        end
        version.strip!.chomp!
        if version == ""
          stderr.puts "Attempt to use git via command '#{git_guess}' to figure out the version failed"
          return 1
        end
        short_version = version[0..7]

        app_docker_images = AppDockerImages.new(
          project_root: Brut.container.project_root,
          organization: Brut.container.organization,
          app_id: Brut.container.app_id,
          short_version:
        )

        FileUtils.chdir Brut.container.project_root do

          stdout.puts "Generating Dockerfiles"
          images.each do |name:, cmd:, dockerfile:|

            stdout.puts "Creating '#{dockerfile}' for '#{name}' that will use command '#{cmd}'"

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

          stdout.puts "Building images"
          docker_quiet_option = if global_options.log_level != "debug"
                                  "--quiet"
                                else
                                  ""
                                end
          images.each do |image_name:, dockerfile:|
            stdout.puts "Creating docker image with name '#{image_name}' and platform '#{platform}'"
            command = %{docker build #{docker_quiet_option} --build-arg app_git_sha1=#{version} --file #{Brut.container.project_root}/#{dockerfile} --platform #{platform} --tag #{image_name} .}
            if options.dry_run?
              stdout.puts "Would run '#{command}'"
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
    def default_command_class = Git
    def opts = [
      [ "--[no-]check-branch", "If true, requires that you are on 'main' (default true)" ],
      [ "--[no-]check-changes", "If true, requires that you have committed all local changes (default true)" ],
      [ "--[no-]check-push", "If true, requires that you are in sync with origin/main (default true)" ],
    ]

    class Git < Brut::CLI::Commands::BaseCommand
      def description = "Perform the check assuming Git is the version-control system"
      def opts = self.parent_command.opts

      def run

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
          stderr.puts "You are not on the 'main' branch, but on '#{branch}'"
          if options.check_branch?
            stderr.puts "You may only deploy from main"
            return 1
          else
            checks_ignored += 1
            stderr.puts "Ignoring..."
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
          stderr.puts "You have un-committed changes:"
          stderr.puts
          local_changes.split(/\n/).each do |change|
            checks_ignored += 1
            stderr.puts "  #{change}"
          end
          stderr.puts
          if options.check_changes?
            stderr.puts "Commit or revert these, then push to origin"
            return 1
          else
            checks_ignored += 1
            stderr.puts "Ignoring..."
          end
        end

        rev_list = ""
        system!("git rev-list --left-right --count origin/main...main") do |output|
          rev_list << output
        end
        remote_ahead, local_ahead = rev_list.strip.chomp.split(/\t/,2).map(&:to_i)
        if remote_ahead != 0
          stderr.puts "There are commits in origin you don't have."
          if options.check_push?
            stderr.puts "Pull those in, re-run bin/ci, THEN deploy"
            return 1
          else
            checks_ignored += 1
            stderr.puts "Ignoring..."
          end
        end

        if local_ahead != 0
          stderr.puts "You have not pushed to origin."
          if options.check_push?
            stderr.puts "Push to origin before deploying"
            return 1
          else
            checks_ignored += 1
            stderr.puts "Ignoring..."
          end
        end
        if checks_ignored == 0
          stdout.puts "All checks passed"
        else
          stdout.puts "#{checks_ignored} checks failed, but ignored"
        end

        0
      end
    end
  end
end

