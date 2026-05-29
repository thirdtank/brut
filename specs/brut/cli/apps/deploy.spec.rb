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

  # new approach to deploy: one subcommand for each supported deploy type, with the default
  # determined by some sort of configuration option:
  #
  # brut deploy heroku
  # brut deploy docker-compose
  # brut deploy # => whatever some default is
  #
  # # Heroku (currently implemented)
  #
  # -> check that everything is committed and pushed
  # -> Read deploy config, validate it's for Heroku
  # -> Generate Dockerfiles for each process type
  # -> Build all docker images
  # -> Push them to Heroku
  # -> Call Heroku deploy commands
  #
  # # Docker Compose
  #
  # Just pushes to DockerHub, does not actually deploy the pushed image
  #
  # -> check that everything is committed and pushed
  # -> Read deploy config, validate it's for DockerHub
  # -> Validate that docker-compose.yml is correct
  #    -> if not, offer to generate, but everything must start over
  # -> Build docker image
  # -> Push them to DockerHub
  # -> Output that 
  #
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
end
