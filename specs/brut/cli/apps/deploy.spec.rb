require "spec_helper"
require "tmpdir"
require "pathname"
require "fileutils"
require "brut/cli"

RSpec.describe Brut::CLI::Apps::Deploy, cli_command: true do
  let(:test_container) { Brut::Framework::Container.new }
  let(:tmpdir) { Dir.mktmpdir }

  before do
    allow(Brut).to receive(:container).and_return(test_container)
    Brut.container.store("project_root",Pathname,"",Pathname(tmpdir) / "project_root")
    Brut.container.store("app_organization",String,"","exampleorg")
    Brut.container.store("app_id",String,"","exampleapp")
  end

  after do
    FileUtils.remove_entry(tmpdir)
    Object.send(:remove_const, :AppDeployConfig) if Object.const_defined?(:AppDeployConfig)
  end


  describe described_class::Heroku do
    subject(:command) { described_class.new }

    let(:git_version) { "963413c118bca5d9fee3fde3030baef8400836e1" }

    context "has a deploy config" do
      context "deploy config is for Heroku" do
        context "has a Dockerfile" do
          context "passes git checks" do
            context "is logged into Heroku" do
              it "generates Dockerfiles and builds images with a magical incantation, then does a release" do
                deploy_config_path = Brut.container.project_root / "deploy" / "deploy_config.rb"
                dockerfile = Brut.container.project_root / "deploy" / "Dockerfile"
                FileUtils.mkdir_p deploy_config_path.dirname
                File.open(deploy_config_path.to_s, "w") do |file|
                  file.puts "class AppDeployConfig < Brut::CLI::Apps::Deploy::Heroku::DeployConfig"
                  file.puts "  def additional_processes = ["
                  file.puts "   process_description('sidekiq', [ 'bundle', 'exec', 'bin/run sidekiq' ]),"
                  file.puts "  ]"
                  file.puts "end"
                end
                File.open(dockerfile, "w") do |file|
                  file.puts "# Test Dockerfile, this is not real"
                end
                git_checks = instance_double(Brut::CLI::Apps::Deploy::GitChecks)
                allow(Brut::CLI::Apps::Deploy::GitChecks).to receive(:new).and_return(git_checks)
                allow(git_checks).to receive(:check!).and_return(
                  Brut::CLI::Apps::Deploy::GitChecks::Results.new
                )

                execution_context = test_execution_context do |executor|
                  executor.on_command("git rev-parse HEAD", output: git_version)
                end
                exit_status = command.execute(execution_context)
                expect(exit_status).to eq(0)
                dockerfiles = []
                Dir[dockerfile.dirname / "*"].each do |file|
                  if file =~ /Dockerfile\..*$/
                    dockerfiles << Pathname(file).basename.to_s
                  end
                end
                [ "web", "release", "sidekiq" ].each do |name|
                  dockerfile_name = "Dockerfile.#{name}"
                  dockerfile_path = dockerfile.dirname / dockerfile_name
                  expect(dockerfiles).to include(dockerfile_name)
                  contents = File.read(dockerfile_path).split(/\n/)
                  cmd = case name
                        when "web" then "bin/run"
                        when "sidekiq" then "bin/run sidekiq"
                        when "release" then "bin/release"
                        else
                          raise "BUG: No such process type with name '#{name}'"
                        end
                  image_name = "registry.heroku.com/exampleapp/#{name}"
                  expect(contents[-1]).to match(/^CMD.*#{cmd}/)
                  expect(execution_context).to have_executed(
                    %{docker buildx build --provenance=false --build-arg app_git_sha1=#{git_version} --file #{dockerfile_path} --platform linux/amd64 --push --tag #{image_name} . 2>&1}
                  )
                end
                expect(execution_context).to have_executed(
                  "heroku container:release release sidekiq web -a exampleapp"
                )
              end
              it "generates Dockerfiles and builds images with a magical incantation but skips release when --build-only is used" do
                deploy_config_path = Brut.container.project_root / "deploy" / "deploy_config.rb"
                dockerfile = Brut.container.project_root / "deploy" / "Dockerfile"
                FileUtils.mkdir_p deploy_config_path.dirname
                File.open(deploy_config_path.to_s, "w") do |file|
                  file.puts "class AppDeployConfig < Brut::CLI::Apps::Deploy::Heroku::DeployConfig"
                  file.puts "  def additional_processes = ["
                  file.puts "   process_description('sidekiq', [ 'bundle', 'exec', 'bin/run sidekiq' ]),"
                  file.puts "  ]"
                  file.puts "end"
                end
                File.open(dockerfile, "w") do |file|
                  file.puts "# Test Dockerfile, this is not real"
                end
                git_checks = instance_double(Brut::CLI::Apps::Deploy::GitChecks)
                allow(Brut::CLI::Apps::Deploy::GitChecks).to receive(:new).and_return(git_checks)
                allow(git_checks).to receive(:check!).and_return(
                  Brut::CLI::Apps::Deploy::GitChecks::Results.new
                )

                execution_context = test_execution_context(
                  options: { "build-only" => true },
                ) do |executor|
                  executor.on_command("git rev-parse HEAD", output: git_version)
                end
                exit_status = command.execute(execution_context)
                expect(exit_status).to eq(0)
                dockerfiles = []
                Dir[dockerfile.dirname / "*"].each do |file|
                  if file =~ /Dockerfile\..*$/
                    dockerfiles << Pathname(file).basename.to_s
                  end
                end
                [ "web", "release", "sidekiq" ].each do |name|
                  dockerfile_name = "Dockerfile.#{name}"
                  dockerfile_path = dockerfile.dirname / dockerfile_name
                  expect(dockerfiles).to include(dockerfile_name)
                  contents = File.read(dockerfile_path).split(/\n/)
                  cmd = case name
                        when "web" then "bin/run"
                        when "sidekiq" then "bin/run sidekiq"
                        when "release" then "bin/release"
                        else
                          raise "BUG: No such process type with name '#{name}'"
                        end
                  image_name = "registry.heroku.com/exampleapp/#{name}"
                  expect(contents[-1]).to match(/^CMD.*#{cmd}/)
                  expect(execution_context).to have_executed(
                    %{docker buildx build --provenance=false --build-arg app_git_sha1=#{git_version} --file #{dockerfile_path} --platform linux/amd64 --load --tag #{image_name} . 2>&1}
                  )
                end
                expect(execution_context).not_to have_executed(
                  "heroku container:release release sidekiq web -a exampleapp"
                )
              end
            end
            context "not logged into Heroku" do
              it "generates an error" do
                deploy_config_path = Brut.container.project_root / "deploy" / "deploy_config.rb"
                dockerfile = Brut.container.project_root / "deploy" / "Dockerfile"
                FileUtils.mkdir_p deploy_config_path.dirname
                File.open(deploy_config_path.to_s, "w") do |file|
                  file.puts "class AppDeployConfig < Brut::CLI::Apps::Deploy::Heroku::DeployConfig"
                  file.puts "end"
                end
                File.open(dockerfile, "w") do |file|
                  file.puts "# Test Dockerfile, this is not real"
                end
                git_checks = instance_double(Brut::CLI::Apps::Deploy::GitChecks)
                allow(Brut::CLI::Apps::Deploy::GitChecks).to receive(:new).and_return(git_checks)
                allow(git_checks).to receive(:check!).and_return(
                  Brut::CLI::Apps::Deploy::GitChecks::Results.new
                )

                execution_context = test_execution_context do |executor|
                  executor.on_command("heroku container:login", raise_error: "Not logged in")
                end
                exit_status = command.execute(execution_context)
                expect(exit_status).not_to eq(0)
                expect(execution_context.stderr.string).to include("Not logged into Heroku")
              end
            end
          end
          context "does not pass git checks" do
            it "generates an error" do
              deploy_config_path = Brut.container.project_root / "deploy" / "deploy_config.rb"
              dockerfile = Brut.container.project_root / "deploy" / "Dockerfile"
              FileUtils.mkdir_p deploy_config_path.dirname
              File.open(deploy_config_path.to_s, "w") do |file|
                file.puts "class AppDeployConfig < Brut::CLI::Apps::Deploy::Heroku::DeployConfig"
                file.puts "end"
              end
              File.open(dockerfile, "w") do |file|
                file.puts "# Test Dockerfile, this is not real"
              end
              git_checks = instance_double(Brut::CLI::Apps::Deploy::GitChecks)
              allow(Brut::CLI::Apps::Deploy::GitChecks).to receive(:new).and_return(git_checks)
              allow(git_checks).to receive(:check!).and_return(
                Brut::CLI::Apps::Deploy::GitChecks::Results.new("main-branch" => "Not on main branch")
              )

              execution_context = test_execution_context
              exit_status = command.execute(execution_context)
              expect(exit_status).not_to eq(0)
              expect(execution_context.stderr.string).to include("Not on main branch")
            end
          end
        end
        context "does not have a Dockerfile" do
          it "generates an error" do
            deploy_config_path = Brut.container.project_root / "deploy" / "deploy_config.rb"
            FileUtils.mkdir_p deploy_config_path.dirname
            File.open(deploy_config_path.to_s, "w") do |file|
              file.puts "class AppDeployConfig < Brut::CLI::Apps::Deploy::Heroku::DeployConfig"
              file.puts "end"
            end

            execution_context = test_execution_context
            exit_status = command.execute(execution_context)
            expect(exit_status).not_to eq(0)
            expect(execution_context.stderr.string).to include("deploy/Dockerfile")
          end
        end
      end
      context "deploy config is not for Heroku" do
        it "outputs an error if it does not define AppDeployConfig" do
          deploy_config_path = Brut.container.project_root / "deploy" / "deploy_config.rb"
          FileUtils.mkdir_p deploy_config_path.dirname
          File.open(deploy_config_path.to_s, "w") do |file|
            file.puts "class Foo < Brut::CLI::Apps::Deploy::DeployConfig"
            file.puts "end"
          end

          execution_context = test_execution_context
          exit_status = command.execute(execution_context)
          expect(exit_status).not_to eq(0)
          expect(execution_context.stderr.string).to include("AppDeployConfig")
        end
        it "outputs an error if the base class is wrong" do
          deploy_config_path = Brut.container.project_root / "deploy" / "deploy_config.rb"
          FileUtils.mkdir_p deploy_config_path.dirname
          File.open(deploy_config_path.to_s, "w") do |file|
            file.puts "class AppDeployConfig < Brut::CLI::Apps::Deploy::DeployConfig"
            file.puts "end"
          end

          execution_context = test_execution_context
          exit_status = command.execute(execution_context)
          expect(exit_status).not_to eq(0)
          expect(execution_context.stderr.string).to include("Deploy::Heroku::DeployConfig")
        end
      end
    end
    context "no deploy config" do
      it "outputs an error" do
        execution_context = test_execution_context
        exit_status = command.execute(execution_context)
        expect(exit_status).not_to eq(0)
        expect(execution_context.stderr.string).to match(/\/deploy\/deploy_config.rb/)
      end
    end
  end

  describe described_class::Docker do
    subject(:command) { described_class.new }

    let(:git_version) { "963413c118bca5d9fee3fde3030baef8400836e1" }

    context "has a deploy config" do
      context "deploy config is for Docker" do
        context "has a Dockerfile" do
          context "passes git checks" do
            it "builds images and pushes" do
              deploy_config_path = Brut.container.project_root / "deploy" / "deploy_config.rb"
              dockerfile = Brut.container.project_root / "deploy" / "Dockerfile"
              FileUtils.mkdir_p deploy_config_path.dirname
              File.open(deploy_config_path.to_s, "w") do |file|
                file.puts "class AppDeployConfig < Brut::CLI::Apps::Deploy::DeployConfig"
                file.puts "  def additional_processes = ["
                file.puts "    process_description('sidekiq', [ 'bundle', 'exec', 'bin/run sidekiq' ]),"
                file.puts "  ]"
                file.puts "end"
              end
              File.open(dockerfile, "w") do |file|
                file.puts "# Test Dockerfile, this is not real"
              end
              git_checks = instance_double(Brut::CLI::Apps::Deploy::GitChecks)
              allow(Brut::CLI::Apps::Deploy::GitChecks).to receive(:new).and_return(git_checks)
              allow(git_checks).to receive(:check!).and_return(
                Brut::CLI::Apps::Deploy::GitChecks::Results.new
              )

              execution_context = test_execution_context do |executor|
                executor.on_command("git rev-parse HEAD", output: git_version)
              end
              exit_status = command.execute(execution_context)
              expect(exit_status).to eq(0)

              short_version = git_version[0..7]
              image_name = %{exampleorg/exampleapp:#{short_version}}

              expect(execution_context).to have_executed(
                %{docker build --build-arg app_git_sha1=#{git_version} --file #{dockerfile} --platform linux/amd64 --tag #{image_name} . 2>&1}
              )
              expect(execution_context).to have_executed(
                %{docker image push #{image_name}}
              )
            end
            it "builds images only when --build-only is specified" do
              deploy_config_path = Brut.container.project_root / "deploy" / "deploy_config.rb"
              dockerfile = Brut.container.project_root / "deploy" / "Dockerfile"
              FileUtils.mkdir_p deploy_config_path.dirname
              File.open(deploy_config_path.to_s, "w") do |file|
                file.puts "class AppDeployConfig < Brut::CLI::Apps::Deploy::DeployConfig"
                file.puts "  def additional_processes = ["
                file.puts "    process_description('sidekiq', [ 'bundle', 'exec', 'bin/run sidekiq' ]),"
                file.puts "  ]"
                file.puts "end"
              end
              File.open(dockerfile, "w") do |file|
                file.puts "# Test Dockerfile, this is not real"
              end
              git_checks = instance_double(Brut::CLI::Apps::Deploy::GitChecks)
              allow(Brut::CLI::Apps::Deploy::GitChecks).to receive(:new).and_return(git_checks)
              allow(git_checks).to receive(:check!).and_return(
                Brut::CLI::Apps::Deploy::GitChecks::Results.new
              )

              execution_context = test_execution_context(
                options: { "build-only" => true }
              )do |executor|
                executor.on_command("git rev-parse HEAD", output: git_version)
              end
              exit_status = command.execute(execution_context)
              expect(exit_status).to eq(0)

              short_version = git_version[0..7]
              image_name = %{exampleorg/exampleapp:#{short_version}}

              expect(execution_context).to have_executed(
                %{docker build --build-arg app_git_sha1=#{git_version} --file #{dockerfile} --platform linux/amd64 --tag #{image_name} . 2>&1}
              )
              expect(execution_context).not_to have_executed(
                %{docker image push #{image_name}}
              )
            end
            it "builds images and pushes to a non-Dockerhub repo" do
              deploy_config_path = Brut.container.project_root / "deploy" / "deploy_config.rb"
              dockerfile = Brut.container.project_root / "deploy" / "Dockerfile"
              FileUtils.mkdir_p deploy_config_path.dirname
              File.open(deploy_config_path.to_s, "w") do |file|
                file.puts "class AppDeployConfig < Brut::CLI::Apps::Deploy::DeployConfig"
                file.puts "  def registry_hostname = 'docker.example.com'"
                file.puts "  def additional_processes = ["
                file.puts "    process_description('sidekiq', [ 'bundle', 'exec', 'bin/run sidekiq' ]),"
                file.puts "  ]"
                file.puts "end"
              end
              File.open(dockerfile, "w") do |file|
                file.puts "# Test Dockerfile, this is not real"
              end
              git_checks = instance_double(Brut::CLI::Apps::Deploy::GitChecks)
              allow(Brut::CLI::Apps::Deploy::GitChecks).to receive(:new).and_return(git_checks)
              allow(git_checks).to receive(:check!).and_return(
                Brut::CLI::Apps::Deploy::GitChecks::Results.new
              )

              execution_context = test_execution_context do |executor|
                executor.on_command("git rev-parse HEAD", output: git_version)
              end
              exit_status = command.execute(execution_context)
              expect(exit_status).to eq(0)

              short_version = git_version[0..7]
              image_name = %{docker.example.com/exampleorg/exampleapp:#{short_version}}

              expect(execution_context).to have_executed(
                %{docker build --build-arg app_git_sha1=#{git_version} --file #{dockerfile} --platform linux/amd64 --tag #{image_name} . 2>&1}
              )
              expect(execution_context).to have_executed(
                %{docker image push #{image_name}}
              )
            end
          end
        end
        context "does not pass git checks" do
          it "generates an error" do
            deploy_config_path = Brut.container.project_root / "deploy" / "deploy_config.rb"
            dockerfile = Brut.container.project_root / "deploy" / "Dockerfile"
            FileUtils.mkdir_p deploy_config_path.dirname
            File.open(deploy_config_path.to_s, "w") do |file|
              file.puts "class AppDeployConfig < Brut::CLI::Apps::Deploy::DeployConfig"
              file.puts "end"
            end
            File.open(dockerfile, "w") do |file|
              file.puts "# Test Dockerfile, this is not real"
            end
            git_checks = instance_double(Brut::CLI::Apps::Deploy::GitChecks)
            allow(Brut::CLI::Apps::Deploy::GitChecks).to receive(:new).and_return(git_checks)
            allow(git_checks).to receive(:check!).and_return(
              Brut::CLI::Apps::Deploy::GitChecks::Results.new("main-branch" => "Not on main branch")
            )

            execution_context = test_execution_context
            exit_status = command.execute(execution_context)
            expect(exit_status).not_to eq(0)
            expect(execution_context.stderr.string).to include("Not on main branch")
          end
        end
      end
      context "does not have a Dockerfile" do
        it "generates an error" do
          deploy_config_path = Brut.container.project_root / "deploy" / "deploy_config.rb"
          FileUtils.mkdir_p deploy_config_path.dirname
          File.open(deploy_config_path.to_s, "w") do |file|
            file.puts "class AppDeployConfig < Brut::CLI::Apps::Deploy::DeployConfig"
            file.puts "end"
          end

          execution_context = test_execution_context
          exit_status = command.execute(execution_context)
          expect(exit_status).not_to eq(0)
          expect(execution_context.stderr.string).to include("deploy/Dockerfile")
        end
      end
    end
    context "deploy config is not for Docker" do
      it "outputs an error if it does not define AppDeployConfig" do
        deploy_config_path = Brut.container.project_root / "deploy" / "deploy_config.rb"
        FileUtils.mkdir_p deploy_config_path.dirname
        File.open(deploy_config_path.to_s, "w") do |file|
          file.puts "class Foo < Brut::CLI::Apps::Deploy::DeployConfig"
          file.puts "end"
        end

        execution_context = test_execution_context
        exit_status = command.execute(execution_context)
        expect(exit_status).not_to eq(0)
        expect(execution_context.stderr.string).to include("AppDeployConfig")
      end
      it "outputs an error if the base class is wrong" do
        deploy_config_path = Brut.container.project_root / "deploy" / "deploy_config.rb"
        FileUtils.mkdir_p deploy_config_path.dirname
        File.open(deploy_config_path.to_s, "w") do |file|
          file.puts "class AppDeployConfig < Object"
          file.puts "end"
        end

        execution_context = test_execution_context
        exit_status = command.execute(execution_context)
        expect(exit_status).not_to eq(0)
        expect(execution_context.stderr.string).to include("Deploy::DeployConfig")
      end
    end
    context "no deploy config" do
      it "outputs an error" do
        execution_context = test_execution_context
        exit_status = command.execute(execution_context)
        expect(exit_status).not_to eq(0)
        expect(execution_context.stderr.string).to match(/\/deploy\/deploy_config.rb/)
      end
    end
  end
  describe described_class::DockerCompose::Check do
    subject(:command) { described_class.new }
    context "there is a docker-compose file" do
      context "there is a deploy_config.rb file" do
        context "docker-compose contents look good" do
          it "outputs success" do
            deploy_config_path = Brut.container.project_root / "deploy" / "deploy_config.rb"
            FileUtils.mkdir_p deploy_config_path.dirname
            File.open(deploy_config_path.to_s, "w") do |file|
              file.puts "class AppDeployConfig < Brut::CLI::Apps::Deploy::DeployConfig"
              file.puts "  def additional_processes = ["
              file.puts "    process_description('sidekiq', [ 'bundle', 'exec', 'bin/run sidekiq' ]),"
              file.puts "  ]"
              file.puts "end"
            end

            docker_compose_path = Brut.container.project_root / "deploy" / "docker-compose.yml"
            FileUtils.mkdir_p docker_compose_path.dirname
            File.open(docker_compose_path.to_s, "w") do |file|
              file.puts "services:"
              file.puts "  web:"
              file.puts "    image: #{Brut.container.app_organization}/#{Brut.container.app_id}:${DOCKER_IMAGE_TAG}"
              file.puts "    command: [ 'bundle', 'exec', 'bin/run' ]"
              file.puts "  sidekiq:"
              file.puts "    image: #{Brut.container.app_organization}/#{Brut.container.app_id}:${DOCKER_IMAGE_TAG}"
              file.puts "    command: [ 'bundle', 'exec', 'bin/run sidekiq' ]"
            end

            execution_context = test_execution_context
            exit_status = command.execute(execution_context)
            expect(exit_status).to eq(0)
          end
        end
        context "docker-compose contents don't look good" do
          it "outputs an error" do
            deploy_config_path = Brut.container.project_root / "deploy" / "deploy_config.rb"
            FileUtils.mkdir_p deploy_config_path.dirname
            File.open(deploy_config_path.to_s, "w") do |file|
              file.puts "class AppDeployConfig < Brut::CLI::Apps::Deploy::DeployConfig"
              file.puts "  def additional_processes = ["
              file.puts "    process_description('sidekiq', [ 'bundle', 'exec', 'bin/run sidekiq' ]),"
              file.puts "  ]"
              file.puts "end"
            end

            docker_compose_path = Brut.container.project_root / "deploy" / "docker-compose.yml"
            FileUtils.mkdir_p docker_compose_path.dirname
            File.open(docker_compose_path.to_s, "w") do |file|
              file.puts "services:"
              file.puts "  web:"
              file.puts "    image: foo/bar:${DOCKER_IMAGE_TAG}"
              file.puts "    command: [ 'blah' ]"
              file.puts "  blah:"
              file.puts "    image: foo/bar:${DOCKER_IMAGE_TAG}"
              file.puts "    command: [ 'blah' ]"
            end

            execution_context = test_execution_context
            exit_status = command.execute(execution_context)
            expect(exit_status).not_to eq(0)
            expect(execution_context.stderr.string).to include("service sidekiq: MISSING")
            expect(execution_context.stderr.string).to include("service web: image incorrect")
            expect(execution_context.stderr.string).to include("service web: command incorrect")
            expect(execution_context.stderr.string).to include("service blah: not in deploy config")
          end
        end
      end
      context "there is not a deploy_config.rb file" do
        it "outputs an error" do
          docker_compose_path = Brut.container.project_root / "deploy" / "docker-compose.yml"
          FileUtils.mkdir_p docker_compose_path.dirname
          File.open(docker_compose_path.to_s, "w") do |file|
            file.puts "services:"
            file.puts "  web:"
          end

          execution_context = test_execution_context
          exit_status = command.execute(execution_context)
          expect(exit_status).not_to eq(0)
          expect(execution_context.stderr.string).to match(/\/deploy\/deploy_config.rb/)
        end
      end
    end
    context "no docker-compose file" do
      it "outputs an error" do
        execution_context = test_execution_context
        exit_status = command.execute(execution_context)
        expect(exit_status).not_to eq(0)
        expect(execution_context.stderr.string).to match(/\/deploy\/docker-compose.yml/)
      end
    end
  end
  describe described_class::DockerCompose::Generate do
    subject(:command) { described_class.new }
    context "there is a docker-compose file" do
      it "removes unused services, adds new ones, and updates image/command of existing ones" do
        deploy_config_path = Brut.container.project_root / "deploy" / "deploy_config.rb"
        FileUtils.mkdir_p deploy_config_path.dirname
        File.open(deploy_config_path.to_s, "w") do |file|
          file.puts "class AppDeployConfig < Brut::CLI::Apps::Deploy::DeployConfig"
          file.puts "  def additional_processes = ["
          file.puts "    process_description('sidekiq', [ 'bundle', 'exec', 'bin/run sidekiq' ]),"
          file.puts "  ]"
          file.puts "end"
        end

        docker_compose_path = Brut.container.project_root / "deploy" / "docker-compose.yml"
        FileUtils.mkdir_p docker_compose_path.dirname
        docker_compose_contents = {
          "services" => {
            "web" => {
              "image" => "exampleorg/exampleapp:${DOCKER_IMAGE_TAG}",
              "command" => [ "bundle" , "exec", "bin/run web" ],
              "env_file" => "/etc/#{Brut.container.app_id}/env",
              "extra_hosts" => [
                "host.docker.internal:host-gateway",
                "host.docker.internal:host-gateway-2000",
              ],
              "restart" => "unless-stopped",
            },
            "foo" => {
              "image" => "exampleorg/exampleapp:${DOCKER_IMAGE_TAG}",
              "command" => [ "bundle" , "exec", "bin/run foo" ],
              "extra_hosts" => [
                "host.docker.internal:host-gateway",
                "host.docker.internal:host-gateway-2000",
              ],
              "restart" => "unless-stopped",
            },
          }
        }
        File.open(docker_compose_path.to_s, "w") do |file|
          file.puts YAML.dump(docker_compose_contents)
        end

        execution_context = test_execution_context
        exit_status = command.execute(execution_context)
        expect(exit_status).to eq(0)
        docker_compose_path = Brut.container.project_root / "deploy" / "docker-compose.yml"
        expect(docker_compose_path.exist?).to eq(true)
        contents = YAML.load(File.read(docker_compose_path))

        aggregate_failures do
          expect(contents["services"]["web"]).not_to eq(nil)
          expect(contents["services"]["sidekiq"]).not_to eq(nil)
          expect(contents["services"]["foo"]).to eq(nil)
        end
        aggregate_failures do
          web = contents["services"]["web"]
          expect(web["image"]).to eq("#{Brut.container.app_organization}/#{Brut.container.app_id}:${DOCKER_IMAGE_TAG}")
          expect(web["command"]).to eq([ "bundle", "exec", "bin/run"])
          expect(web["ports"]).to eq(nil) # not inserted if not there
          expect(web["env_file"]).to eq("/etc/#{Brut.container.app_id}/env")
          expect(web["extra_hosts"][0]).to eq("host.docker.internal:host-gateway")
          expect(web["extra_hosts"][1]).to eq("host.docker.internal:host-gateway-2000")
          expect(web["restart"]).to eq("unless-stopped")
        end
        aggregate_failures do
          sidekiq = contents["services"]["sidekiq"]
          expect(sidekiq["image"]).to eq("#{Brut.container.app_organization}/#{Brut.container.app_id}:${DOCKER_IMAGE_TAG}")
          expect(sidekiq["command"]).to eq([ "bundle", "exec", "bin/run sidekiq"])
          expect(sidekiq["ports"]).to eq(nil)
          expect(sidekiq["env_file"]).to eq("/etc/#{Brut.container.app_id}/env")
          expect(sidekiq["extra_hosts"][0]).to eq("host.docker.internal:host-gateway")
          expect(sidekiq["restart"]).to eq("unless-stopped")
        end
      end
    end
    context "no docker-compose file" do
      it "generates a new file with services defined in AppDeployConfig" do
        deploy_config_path = Brut.container.project_root / "deploy" / "deploy_config.rb"
        FileUtils.mkdir_p deploy_config_path.dirname
        File.open(deploy_config_path.to_s, "w") do |file|
          file.puts "class AppDeployConfig < Brut::CLI::Apps::Deploy::DeployConfig"
          file.puts "  def additional_processes = ["
          file.puts "    process_description('sidekiq', [ 'bundle', 'exec', 'bin/run sidekiq' ]),"
          file.puts "  ]"
          file.puts "end"
        end

        execution_context = test_execution_context
        exit_status = command.execute(execution_context)
        expect(exit_status).to eq(0)
        docker_compose_path = Brut.container.project_root / "deploy" / "docker-compose.yml"
        expect(docker_compose_path.exist?).to eq(true)
        contents = YAML.load(File.read(docker_compose_path))

        aggregate_failures do
          expect(contents["services"]["web"]).not_to eq(nil)
          expect(contents["services"]["sidekiq"]).not_to eq(nil)
        end
        aggregate_failures do
          web = contents["services"]["web"]
          expect(web["image"]).to eq("#{Brut.container.app_organization}/#{Brut.container.app_id}:${DOCKER_IMAGE_TAG}")
          expect(web["command"]).to eq([ "bundle", "exec", "bin/run"])
          expect(web["ports"][0]).to eq("127.0.0.1:6502:6502")
          expect(web["env_file"]).to eq("/etc/#{Brut.container.app_id}/env")
          expect(web["extra_hosts"][0]).to eq("host.docker.internal:host-gateway")
          expect(web["restart"]).to eq("unless-stopped")
        end
        aggregate_failures do
          sidekiq = contents["services"]["sidekiq"]
          expect(sidekiq["image"]).to eq("#{Brut.container.app_organization}/#{Brut.container.app_id}:${DOCKER_IMAGE_TAG}")
          expect(sidekiq["command"]).to eq([ "bundle", "exec", "bin/run sidekiq"])
          expect(sidekiq["ports"]).to eq(nil)
          expect(sidekiq["env_file"]).to eq("/etc/#{Brut.container.app_id}/env")
          expect(sidekiq["extra_hosts"][0]).to eq("host.docker.internal:host-gateway")
          expect(sidekiq["restart"]).to eq("unless-stopped")
        end
      end
    end
  end
end
