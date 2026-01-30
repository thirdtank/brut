require "spec_helper"
require "stringio"
require "dotenv"

require "brut/cli"
require "brut/framework/project_environment"

RSpec.describe Brut::CLI::Runner do

  let(:project_root) {
    Pathname(__dir__) / ".." / ".." / "support" / "fake_project_root"
  }
  let(:sub_command_returns_10) {
    command_class = Class.new(Brut::CLI::Commands::BaseCommand) do
      def description = "Sub Command Returning 10"
      def name = "sub_num"
      def opts
        [
          [ "--blah=VALUE" ]
        ]
      end
      def run
        10
      end
      def default_rack_env = nil
      def bootstrap? = true
    end
    command_class.new
  }
  let(:sub_command_returns_object) {
    command_class = Class.new(Brut::CLI::Commands::BaseCommand) do
      def description = "Sub Command Returning an Object"
      def name = "sub_obj"
      def default_rack_env = "test"
      def opts
        [
          [ "--crud=VALUE" ]
        ]
      end
      def run
        Object.new
      end
      def bootstrap? = false
    end
    command_class.new
  }
  let(:sub_command_sys_exec_error) {
    command_class = Class.new(Brut::CLI::Commands::BaseCommand) do
      def description = "Sub Command returning a system exec error"
      def name = "sub_sys"
      def opts = []
      def run
        raise Brut::CLI::SystemExecError.new("ls -l", 20)
      end
    end
    command_class.new
  }
  let(:sub_command_cli_error) {
    command_class = Class.new(Brut::CLI::Commands::BaseCommand) do
      def description = "Sub Command returning a CLI error"
      def name = "sub_clierror"
      def opts = []
      def run
        raise Brut::CLI::Error.new("OH NOES")
      end
    end
    command_class.new
  }
  let(:sub_command_raises) {
    command_class = Class.new(Brut::CLI::Commands::BaseCommand) do
      def description = "Sub Command raising an error"
      def name = "sub_raise"
      def opts = []
      def run
        raise "OH NOES"
      end
    end
    command_class.new
  }
  let(:app) { 
    sub_commands = [
      sub_command_returns_10,
      sub_command_returns_object,
      sub_command_sys_exec_error,
      sub_command_cli_error,
      sub_command_raises,
    ]
    app_command_class = Class.new(Brut::CLI::Commands::BaseCommand) do
      attr_accessor :commands, :default_command
      def description = "App Command"
      def opts
        [
          [ "--verbose" ]
        ]
      end
    end
    app_command_class.new.tap { |app|
      app.commands = sub_commands
      app.default_command = sub_command_returns_10
    }
  }

  let(:stdout) { StringIO.new }
  let(:stderr) { StringIO.new }
  let(:stdin)  { StringIO.new }

  subject(:runner) { described_class.new(app, project_root:, stdout:, stderr:, stdin:) }

  before do
    if !defined? Bootstrap
      Bootstrap = Class.new
    end

    @env_keys = ENV.keys
  end
  after do
    ENV.keys.each do |key|
      if !@env_keys.include?(key)
        ENV.delete(key)
      end
    end
  end

  describe "#run!" do
    it "calls #execute on the command found, passing along parsed options as the execution context, setting ENV, returning the exit code" do
      env = {}
      result = runner.run!(["--verbose", "sub_num","--blah", "arg1","arg2"], env)
      expect(result).to eq(10)

      aggregate_failures do
        execution_context = sub_command_returns_10.send(:execution_context)
        expect(execution_context.stdout.io).to        eq(stdout)
        expect(execution_context.stderr.io).to        eq(stderr)
        expect(execution_context.stdin).to            eq(stdin)
        expect(execution_context.options.verbose?).to eq(true)
        expect(execution_context.options.blah).to     eq("arg1")
        expect(execution_context.argv).to             eq(["arg2"])
      end
    end
    describe "project environment" do
      context "RACK_ENV is in env" do
        it "ignores --env and uses the value from env" do
          env = { "RACK_ENV" => "production" }
          result = runner.run!(["--env=development", "sub_obj"], env)
          expect(env["RACK_ENV"]).to eq("production")
          expect(stderr.string).to include("--env ignored")
        end
      end
      context "RACK_ENV is not in env" do
        context "--env used" do
          it "uses the value provided" do
            env = {}
            result = runner.run!(["--env=development", "sub_obj"], env)
            expect(env["RACK_ENV"]).to eq("development")
          end
        end
        context "--env not used" do
          context "command does not specify a default" do
            it "is nil" do
              env = {}
              result = runner.run!(["sub_num"], env)
              expect(env["RACK_ENV"]).to eq(nil)
            end
          end
          context "command specifies a default" do
            it "uses the command's default" do
              env = {}
              result = runner.run!(["sub_obj"], env)
              expect(env["RACK_ENV"]).to eq("test")
            end
          end
        end
      end
    end
    describe "bootstrapping" do
      context "project env has been set" do
        context "command wants bootstrapping" do
          it "configures and bootstraps Brut" do
            bootstrap = double(Bootstrap)
            allow(Bootstrap).to receive(:new).and_return(bootstrap)
            allow(bootstrap).to receive(:bootstrap!).and_return(bootstrap)

            result = runner.run!(["sub_num", "--env=development"],{})

            confidence_check { expect(result).to eq(10) }
            expect(bootstrap).to have_received(:bootstrap!)
          end
        end
        context "command does not want bootstrapping" do
          it "configures Brut only" do
            bootstrap = double(Bootstrap)
            allow(Bootstrap).to receive(:new).and_return(bootstrap)
            allow(bootstrap).to receive(:bootstrap!).and_return(bootstrap)
            allow(bootstrap).to receive(:configure_only!).and_return(bootstrap)

            result = runner.run!(["sub_obj", "--env=development"],{})

            confidence_check { expect(result).to eq(0) }
            expect(bootstrap).not_to have_received(:bootstrap!)
            expect(bootstrap).to     have_received(:configure_only!)
          end
        end
      end
      context "project env has not been set" do
        it "does no bootstrapping" do
          bootstrap = double(Bootstrap)
          allow(Bootstrap).to receive(:new).and_return(bootstrap)
          allow(bootstrap).to receive(:bootstrap!).and_return(bootstrap)

          result = runner.run!(["sub_num"],{})

          confidence_check { expect(result).to eq(10) }
          expect(Bootstrap).not_to have_received(:new)
        end
      end
    end
    describe "using dotenv" do
      context "project env has been set" do
        context "to production" do
          it "does not use dotenv" do
            allow(Bundler).to receive(:require)
            allow(Dotenv).to receive(:load)

            result = runner.run!(["sub_num", "--env=production"],{})

            confidence_check { expect(result).to eq(10) }
            expect(Bundler).to    have_received(:require).with(:default)
            expect(Dotenv).not_to have_received(:load)
          end
        end
        context "to test" do
          it "uses dotenv to load the test .env files" do
            allow(Bundler).to receive(:require)

            env = {}
            result = runner.run!(["sub_num", "--env=test"], env)

            confidence_check { expect(result).to eq(10) }
            expect(Bundler).to have_received(:require).with(:default, :test)
            expect(env["SOME_VAL"]).to eq("test")
            expect(env["SOME_LOCAL_VAL"]).to eq("test-local")
          end
        end
        context "to development" do
          it "uses dotenv to load the development .env files" do
            allow(Bundler).to receive(:require)

            env = {}
            result = runner.run!(["sub_num", "--env=development"],env)

            confidence_check { expect(result).to eq(10) }
            expect(Bundler).to have_received(:require).with(:default, :development)
            expect(env["SOME_VAL"]).to eq("development")
            expect(env["SOME_LOCAL_VAL"]).to eq("development-local")
          end
        end
      end
      context "project env has not been set" do
        it "does not use dotenv" do
          allow(Bundler).to receive(:require)
          allow(Dotenv).to receive(:load)

          result = runner.run!(["sub_num"],{})

          confidence_check { expect(result).to eq(10) }
          expect(Bundler).not_to have_received(:require)
          expect(Dotenv).not_to  have_received(:load)
        end
      end
    end
    describe "log level" do
      context "LOG_LEVEL is set in env" do
        it "uses that value, ignoring any command line arguments" do
          env = { "LOG_LEVEL" => "warn" }
          result = runner.run!(["sub_num", "--log-level=debug"], env)
          expect(env["LOG_LEVEL"]).to eq("warn")
          expect(stderr.string).to include("--log-level ignored")
        end
      end
      context "LOG_LEVEL has not been set in the env" do
        it "uses the value for --log-level" do
          env = {}
          result = runner.run!(["sub_num", "--log-level=debug"], env)
          expect(env["LOG_LEVEL"]).to eq("debug")
        end
      end
    end
    describe "exit status" do
      it "interprets an object being returned from execute as a 0 exitstatus" do
        result = runner.run!(["sub_obj"], {})
        expect(result).to eq(0)
      end
      it "interprets a SystemExecError as an error, using its exit status as the exit status" do
        result = runner.run!(["sub_sys"], {})
        expect(result).to eq(20) # see setup
        expect(stderr.string).to match(/ls \-l failed/)
      end
      it "interprets any other CLI error as an error, using 1 as the exit status" do
        result = runner.run!(["sub_clierror"], {})
        expect(result).to eq(1)
        expect(stderr.string).to match(/OH NOES/)
      end
      it "allows non CLI errors to raise" do
        expect {
          runner.run!(["sub_raise"], {})
        }.to raise_error(/OH NOES/)
      end
    end
    describe "default command and options" do
      it "allows the default command options to be used when default command is invoked implicitly" do
        result = runner.run!(["--verbose"], {})
        expect(result).to eq(10) # sub command was called

        execution_context = sub_command_returns_10.send(:execution_context)
        expect(execution_context.options.verbose?).to eq(true)
      end
    end
  end
end
