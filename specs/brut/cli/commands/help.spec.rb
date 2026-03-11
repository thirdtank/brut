require "spec_helper"
require "brut/cli"
require "stringio"
require "optparse"

RSpec.describe Brut::CLI::Commands::Help do

  let(:stdout) { StringIO.new }
  let(:stderr) { StringIO.new }
  let(:stdin)  { StringIO.new }

  let(:command) {
    command_class = Class.new(Brut::CLI::Commands::BaseCommand) do
      def description = "A Test Command"
      def name = "some_command"
      def opts = [
        [ "--foo BAR", "A test option with an argument" ],
        [ "--[no-]crud", "A test option without an argument" ],
      ]
      def run
        raise "OH NOES"
      end
    end
    command_class.new
  }
  let(:app) { 
    sub_commands = [
      command,
    ]
    app_command_class = Class.new(Brut::CLI::Commands::BaseCommand) do
      attr_accessor :commands
      def description = "App Command"
      def name = "test_cli_app"
      def opts
        [
          [ "--verbose" ],
        ]
      end
    end
    app_command_class.new.tap { |app|
      app.commands = sub_commands
    }
  }

  it "prints help on the command its given" do
    option_parser = OptionParser.new
    app.opts.each { |opt| option_parser.on(*opt) }
    help_command = described_class.new(app,option_parser)

    exit_code = help_command.execute(Brut::CLI::Commands::ExecutionContext.new(stdout:stdout))
    expect(exit_code).to eq(0)
    expect(stdout.string).to include("App Command")
    expect(stdout.string).to include("--verbose")
    expect(stdout.string).to include("some_command")
  end

  it "omits headings for stuff that's not there" do
    option_parser = OptionParser.new
    command.opts.each { |opt| option_parser.on(*opt) }
    help_command = described_class.new(command,option_parser)

    exit_code = help_command.execute(Brut::CLI::Commands::ExecutionContext.new(stdout:stdout))
    expect(exit_code).to eq(0)
    expect(stdout.string).not_to include("App Command")
    expect(stdout.string).not_to include("--verbose")
    expect(stdout.string).to include("some_command")
    expect(stdout.string).not_to include("COMMANDS")
  end

end
