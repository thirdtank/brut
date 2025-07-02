require "brut/cli"
class Brut::CLI::Apps::HerokuContainerBasedDeploy < Brut::CLI::Apps::DeployBase
  description "Deploy to Heroku using containers"
  default_command :deploy
  configure_only!

  class Deploy < Brut::CLI::Command
    description "Build images, push them to Heroku, and deploy them"

    detailed_description %{
Manages a deploy process based on using Heroku's Container Registry. See

    https://devcenter.heroku.com/articles/container-registry-and-runtime

    for details. You are assumed to understand this.  This command will make the process somewhat easier.

    This will use deploy/Dockerfile as a template to create one Dockerfile for each process you want to run in Heroku.  deploy/heroku_config.rb is where the processes and their commands are configured.

    The release phase is included automatically, based on bin/release.
}

    opts.on("--platform=PLATFORM","Override default platform. Can be any Docker platform.")
    opts.on("--[no-]dry-run", "Print the commands that would be run and don't actually do anything. Implies --skip-checks")
    opts.on("--[no-]skip-checks", "Skip checks for code having been committed and pushed")
    opts.on("--[no-]deploy", "After images are pushed, actually deploy them")
    opts.on("--[no-]push", "After images are created, push them to Heroku's registry. If false, implies --no-deploy")

    def after_bootstrap(app:)
      @app_id       = app.id
      @organization = app.organization
    end

    def execute
      options.set_default(:deploy, true)
      options.set_default(:push, true)
      if !options.push?
        options[:deploy] = false
      end
      local_repo_checks = Brut::CLI::Apps::DeployBase::GitChecks.new(
        out: @out,
        err: @err,
        executor: @executor,
        warn_only: options.skip_checks? || options.dry_run?
      )
      if options.dry_run?
        def system!(*args)
          out.puts "DRY RUN, NOT EXECUTING '#{args}'"
        end
      end

      version = begin
                  git_guess = %{git rev-parse HEAD}
                  stdout, stderr, status = Open3.capture3(git_guess)
                  if status.success?
                    stdout.strip
                  else
                    raise "Attempt to use git via command '#{git_guess}' to figure out the version failed: #{stdout}#{stderr}"
                  end
                end
      short_version = version[0..7]

      platform = options.platform || "linux/amd64"
      heroku_app_name = @app_id

      out.puts "Reading HerokuConfig:"
      require_relative Brut.container.project_root / "deploy" / "heroku_config"

      additional_images = HerokuConfig.additional_images.map { |name,config|
        cmd = config.fetch(:cmd)
        out.puts "  - #{name} will run #{cmd} in production"
        image_name = %{#{@organization}/#{@app_id}:#{short_version}-#{name}}
        [
          name,
          {
            cmd:,
            image_name:,
            dockerfile: "deploy/Dockerfile.#{name}",
            heroku_image_name: "registry.heroku.com/#{heroku_app_name}/#{name}",
          }
        ]
      }.to_h

      images = {
        "web" => {
          cmd: "bin/run",
          image_name: %{#{@organization}/#{@app_id}:#{short_version}-web},
          dockerfile: "deploy/Dockerfile.web",
          heroku_image_name: "registry.heroku.com/#{heroku_app_name}/web",
        },
        "release" => {
          cmd: "bin/release",
          image_name: %{#{@organization}/#{@app_id}:#{short_version}-release},
          dockerfile: "deploy/Dockerfile.release",
          heroku_image_name: "registry.heroku.com/#{heroku_app_name}/release",
        },
      }.merge(additional_images)

      out.puts "  - release will run bin/release in production"

      local_repo_checks.check!
require_heroku_login!(options)

      FileUtils.chdir Brut.container.project_root do

        out.puts "Generating Dockerfiles"
        images.each do |name,metadata|
          cmd        = metadata.fetch(:cmd)
          dockerfile = metadata.fetch(:dockerfile)

          out.puts "Creating '#{dockerfile}' for '#{name}' that will use command '#{cmd}'"

          File.open(dockerfile,"w") do |file|
            file.puts "# DO NOT EDIT - THIS IS GENERATED"
            file.puts "# To make changes, modifiy deploy/Dockerfile and run #{$0}"
            file.puts File.read("deploy/Dockerfile")
            file.puts
            file.puts "# Added by #{$0}"
            file.puts %{CMD [ "bundle", "exec", "#{cmd}" ]}
          end
        end

        out.puts "Building images"
        docker_quiet_option = if global_options.log_level != "debug"
                                "--quiet"
                              else
                                ""
                              end
        images.each do |name,metadata|
          image_name = metadata.fetch(:image_name)
          dockerfile = metadata.fetch(:dockerfile)


          out.puts "Creating docker image with name '#{image_name}' and platform '#{platform}'"
          command = %{docker build #{docker_quiet_option} --build-arg app_git_sha1=#{version} --file #{Brut.container.project_root}/#{dockerfile} --platform #{platform} --tag #{image_name} .}
          system!(command)
        end

        out.puts "Taggging images for Heroku"
        images.each do |name,metadata|
          image_name        = metadata.fetch(:image_name)
          heroku_image_name = metadata.fetch(:heroku_image_name)

          out.puts "Tagging '#{image_name}' with '#{heroku_image_name}' for Heroku"
          command = %{docker tag #{image_name} #{heroku_image_name}}
          system!(command)
        end

        if options.push?
          out.puts "Pushing to Heroku Registry"
          images.each do |name,metadata|
            heroku_image_name = metadata.fetch(:heroku_image_name)

            out.puts "Pushing '#{heroku_image_name}'"

            command = %{docker push #{docker_quiet_option} #{heroku_image_name}}
            system!(command)
          end
        else
          out.puts "Not pushing images"
        end

        names = images.map(&:first).join(" ")
        deploy_command = "heroku container:release #{names}"
        if options.deploy?
          out.puts "Deploying images to Heroku"
          system!(deploy_command)
        else
          out.puts "Not deploying.  To deploy the images just pushed:"
          out.puts ""
          out.puts "  #{deploy_command}"
        end
      end
    end
  private
    def require_heroku_login!(options)
      if system("heroku whoami")
        out.puts "You are logged in to Heroku"
      else
        out.puts "You are not logged into Heroku."
        out.puts "Please run the following:"
        out.puts ""
        out.puts "heroku auth:login"
        out.puts "heroku container:login"
        out.puts ""
        out.puts "Then, re-run this"
        if options.dry_run?
          out.puts "Dry run - ignoring"
          return
        end
        exit 1
      end
    end
  end
end
