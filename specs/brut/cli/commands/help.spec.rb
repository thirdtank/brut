require "spec_helper"
require "brut/cli"
require "stringio"
require "optparse"

RSpec.describe Brut::CLI::Commands::Help do

  let(:stdout) { StringIO.new }
  let(:stderr) { StringIO.new }
  let(:stdin)  { StringIO.new }

  it "super awesomely formats the option parser"

  it "prints an the option parser to stdout" do
    option_parser = OptionParser.new do |opts|
      opts.banner = "Test app"
    end
    command = described_class.new(instance_double(Brut::CLI::Commands::BaseCommand, commands: []),option_parser)

    exit_code = command.execute(Brut::CLI::Commands::ExecutionContext.new(stdout:stdout))
    expect(exit_code).to eq(0)
    expect(stdout.string).to eq(option_parser.to_s)
  end

  it "allows changing the OptionParser" do
    option_parser1 = OptionParser.new do |opts|
      opts.banner = "Test app"
    end
    option_parser2 = OptionParser.new do |opts|
      opts.banner = "Test command"
    end
    command = described_class.new(instance_double(Brut::CLI::Commands::BaseCommand, commands: []),option_parser1)
    command.option_parser = option_parser2

    exit_code = command.execute(Brut::CLI::Commands::ExecutionContext.new(stdout:stdout))
    expect(exit_code).to eq(0)
    expect(stdout.string).to eq(option_parser2.to_s)
  end

  it "does not want bootsrapping" do
    command = described_class.new(instance_double(Brut::CLI::Commands::BaseCommand),StandardError.new)
    expect(command.bootstrap?).to eq(false)
  end

  it "has no subcommands" do
    command = described_class.new(instance_double(Brut::CLI::Commands::BaseCommand),OptionParser.new)
    expect(command.commands).to eq([])
  end

  it "does not set a project environment" do
    command = described_class.new(instance_double(Brut::CLI::Commands::BaseCommand),OptionParser.new)
    expect(command.default_rack_env).to eq(nil)
  end

end
