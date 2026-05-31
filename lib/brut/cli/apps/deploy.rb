require "brut/cli"
require "fileutils"
require "pathname"
require "yaml"

class Brut::CLI::Apps::Deploy < Brut::CLI::Commands::BaseCommand

  autoload :DeployConfig, "brut/cli/apps/deploy/deploy_config"
  autoload :GitChecks,    "brut/cli/apps/deploy/git_checks"

  def name = "deploy"
  def description = "Deploy your Brut-powered app to production"

  class Docker < Brut::CLI::Commands::BaseCommand
    def description = "Build one docker image to use for all commands in production"
    def opts = [
      [ "--build-only", "Only generate Dockerfiles and build images, do not deploy" ],
    ]
    def default_rack_env = "development"
    def run
      deploy_config_path = Brut.container.project_root / "deploy" / "deploy_config.rb"
      begin
        require deploy_config_path
        if !defined?(AppDeployConfig)
          fatal "#{deploy_config_path} must define the class AppDeployConfig"
          return 1
        end
        if !AppDeployConfig.ancestors.include?(Brut::CLI::Apps::Deploy::DeployConfig)
          fatal "#{deploy_config_path} must define a subclass of Brut::CLI::Apps::Deploy::DeployConfig"
          return 1
        end
        dockerfile = Brut.container.project_root / "deploy" / "Dockerfile"
        if !dockerfile.exist?
          fatal "#{dockerfile} does not exist - it should've been created when you added the Docker Deploy segment"
          return 1
        end
        git_checks = Brut::CLI::Apps::Deploy::GitChecks.new(executor: execution_context.executor)
        results = git_checks.check!
        if results.errors?
          results.errors.each do |_,message|
            fatal message
          end
          return 1
        end
        version = ""
        git_guess = %{git rev-parse HEAD}
        version = capture!(git_guess).strip.chomp
        if version == ""
          fatal "Attempt to use git via command '#{git_guess}' to figure out the version failed"
          return 1
        end
        short_version = version[0..7]

        config = AppDeployConfig.new

        image_name = %{#{Brut.container.app_organization}/#{Brut.container.app_id}:#{short_version}}
        if config.registry_hostname
          image_name = "#{config.registry_hostname}/#{image_name}"
        end
        dockerfile = Brut.container.project_root / "deploy" / "Dockerfile"
        FileUtils.chdir Brut.container.project_root do
          command = %{docker build --build-arg app_git_sha1=#{version} --file #{dockerfile} --platform #{config.platform} --tag #{image_name} . 2>&1}
          system!(command, output: :stream)
        end
        if options.build_only?
          puts "Not pushing image"
        else
          system!("docker image push #{image_name}", output: :stream)
        end

        0
      rescue LoadError => ex
        fatal "Could not find #{deploy_config_path}: #{ex}"
        1
      end

    end
  end

  class Heroku < Brut::CLI::Commands::BaseCommand
    class DeployConfig < Brut::CLI::Apps::Deploy::DeployConfig

      def registry_hostname = "registry.heroku.com"

      def processes = super + [
        process_description("release", "bin/release")
      ]

      def each_dockerfile(&block)
        self.processes.each do |description|
          dockerfile = "Dockerfile.#{description.name}"
          block.(dockerfile, description)
        end
      end
    end
    def default_rack_env = "development"
    def description = "Deploy to Heroku using container-based deployment"
    def opts = [
      [ "--build-only", "Only generate Dockerfiles and build images, do not deploy" ],
    ]
    def run
      deploy_config_path = Brut.container.project_root / "deploy" / "deploy_config.rb"
      begin
        require deploy_config_path
        if !defined?(AppDeployConfig)
          fatal "#{deploy_config_path} must define the class AppDeployConfig"
          return 1
        end
        if !AppDeployConfig.ancestors.include?(Brut::CLI::Apps::Deploy::Heroku::DeployConfig)
          fatal "#{deploy_config_path} must define a subclass of Brut::CLI::Apps::Deploy::Heroku::DeployConfig"
          return 1
        end
        dockerfile = Brut.container.project_root / "deploy" / "Dockerfile"
        if !dockerfile.exist?
          fatal "#{dockerfile} does not exist - it should've been created when you added the Heroku segment"
          return 1
        end
        git_checks = Brut::CLI::Apps::Deploy::GitChecks.new(executor: execution_context.executor)
        results = git_checks.check!
        if results.errors?
          results.errors.each do |_,message|
            fatal message
          end
          return 1
        end
        begin
          command = %{heroku container:login}
          system!(command)
        rescue Brut::CLI::SystemExecError => ex
          fatal(ex)
          fatal("Not logged into Heroku")
          return 1
        end
        config = AppDeployConfig.new
        version = ""
        git_guess = %{git rev-parse HEAD}
        version = capture!(git_guess).strip.chomp
        if version == ""
          fatal "Attempt to use git via command '#{git_guess}' to figure out the version failed"
          return 1
        end
        names = []
        config.each_dockerfile do |process_dockerfile, process_description|
          process_dockerfile_path = dockerfile.dirname / process_dockerfile
          FileUtils.cp dockerfile, process_dockerfile_path
          File.open(dockerfile.dirname / process_dockerfile, "a") do |file|
            file.puts(process_description.cmd_directive)
          end
          image_name = "#{config.registry_hostname}/#{Brut.container.app_id}/#{process_description.name}"
          push_or_load = if options.build_only?
                           "--load"
                         else
                           "--push"
                         end
          command = %{docker buildx build --provenance=false --build-arg app_git_sha1=#{version} --file #{process_dockerfile_path} --platform #{config.platform} #{push_or_load} --tag #{image_name} . 2>&1}
          system!(command, output: :stream)
          names << process_description.name
        end
        deploy_command = "heroku container:release #{names.sort.join(' ')} -a #{Brut.container.app_id}"
        if options.build_only?
          puts "Not deploying"
        else
          system!(deploy_command, output: :stream)
        end

        0
      rescue LoadError => ex
        fatal "Could not find #{deploy_config_path}: #{ex}"
        1
      end
    end
  end
  class DockerCompose < Brut::CLI::Commands::BaseCommand
    def default_rack_env = "development"
    def description = "Manage a docker-compose.yml file to be consistent with your deploy config"
    class Check < Brut::CLI::Commands::BaseCommand
      def description = "Check if the existing docker-compose.yml is consistent with the deploy config"
      def default_rack_env = "development"
      def run
        docker_compose_path = Brut.container.project_root / "deploy" / "docker-compose.yml"
        if !docker_compose_path.exist?
          fatal "Could not find #{docker_compose_path}"
          return 1
        end
        deploy_config_path = Brut.container.project_root / "deploy" / "deploy_config.rb"
        begin
          require deploy_config_path
          if !defined?(AppDeployConfig)
            fatal "#{deploy_config_path} must define the class AppDeployConfig"
            return 1
          end
          if !AppDeployConfig.ancestors.include?(Brut::CLI::Apps::Deploy::DeployConfig)
            fatal "#{deploy_config_path} must define a subclass of Brut::CLI::Apps::Deploy::DeployConfig"
            return 1
          end
          config = AppDeployConfig.new
          docker_compose_contents = YAML.load(File.read(docker_compose_path))
          missing = []
          extra   = []
          wrong   = {}
          failed  = false
          configured_services = []
          expected_image_name = "#{Brut.container.app_organization}/#{Brut.container.app_id}:${DOCKER_IMAGE_TAG}"
          if config.registry_hostname
            expected_image_name = "#{config.registry_hostname}/#{expected_image_name}"
          end
          config.processes.each do |process_description|
            configured_services << process_description.name
            service = docker_compose_contents["services"][process_description.name]
            if service
              image = service["image"]
              cmd   = service["command"]
              if image != expected_image_name
                wrong[process_description] ||= {}
                wrong[process_description][:image] = {
                  expected: expected_image_name,
                  actual: image
                }
                failed = true
              end
              if cmd != process_description.cmd
                wrong[process_description] ||= {}
                wrong[process_description][:command] = {
                  expected: process_description.cmd,
                  actual: cmd
                }
                failed = true
              end
            else
              missing << process_description
              failed = true
            end
          end
          docker_compose_contents["services"].each do |service_name,configuration|
            if !configured_services.include?(service_name)
              extra << service_name
              failed = true
            end
          end
          if failed
            missing.each do |process_description|
              fatal "service #{process_description.name}: MISSING"
            end
            wrong.each do |process_description, problems|
              problems.each do |key,expected_actual|
                fatal "service #{process_description.name}: #{key} incorrect. Expected '#{expected_actual[:expected]}', but got '#{expected_actual[:actual]}'"
              end
            end
            extra.each do |service_name|
              fatal "service #{service_name}: not in deploy config"
            end
            return 1
          end
          0
        rescue LoadError => ex
          fatal "Could not find #{deploy_config_path}: #{ex}"
          1
        end
      end
    end
    class Generate < Brut::CLI::Commands::BaseCommand
      def description = "Generate or update the existing docker-compose.yml based on current deploy config"
      def default_rack_env = "development"
      def run
        docker_compose_path = Brut.container.project_root / "deploy" / "docker-compose.yml"
        deploy_config_path = Brut.container.project_root / "deploy" / "deploy_config.rb"
        begin
          require deploy_config_path
          if !defined?(AppDeployConfig)
            fatal "#{deploy_config_path} must define the class AppDeployConfig"
            return 1
          end
          if !AppDeployConfig.ancestors.include?(Brut::CLI::Apps::Deploy::DeployConfig)
            fatal "#{deploy_config_path} must define a subclass of Brut::CLI::Apps::Deploy::DeployConfig"
            return 1
          end
          config = AppDeployConfig.new
          yaml_contents = if docker_compose_path.exist?
                            YAML.load(File.read(docker_compose_path))
                          else
                            {}
                          end
          yaml_contents["services"] ||= {}

          image_name = "#{Brut.container.app_organization}/#{Brut.container.app_id}:${DOCKER_IMAGE_TAG}"
          if config.registry_hostname
            image_name = "#{config.registry_hostname}/#{image_name}"
          end
          configured_services = []
          config.processes.each do |process_description|
            configured_services << process_description.name
            existing = yaml_contents["services"][process_description.name]
            if !existing
              puts "Creating configuration for '#{process_description.name}'"
              existing = {
                "env_file" => "/etc/#{Brut.container.app_id}/env",
                "extra_hosts" => [
                  "host.docker.internal:host-gateway",
                ],
                "restart" => "unless-stopped",
              }
              if process_description.name == "web"
                existing["ports"] = [
                  "127.0.0.1:6502:6502",
                ]
              end
            else
              puts "Updating image and command for '#{process_description.name}'"
            end
            existing["image"] = image_name
            existing["command"] = process_description.cmd
            yaml_contents["services"][process_description.name] = existing
          end
          trimmed_services = yaml_contents["services"].select { |service_name, service_configuration|
            configured_services.include?(service_name).tap { |exists|
              if !exists
                puts "Removing configuration for '#{service_name}'"
              end
            }
          }.to_h
          yaml_contents["services"] = trimmed_services

          File.open(docker_compose_path,"w") do |file|
            file.puts YAML.dump(yaml_contents)
          end
          0
        rescue LoadError => ex
          fatal "Could not find #{deploy_config_path}: #{ex}"
          1
        end
      end
    end
  end
end
