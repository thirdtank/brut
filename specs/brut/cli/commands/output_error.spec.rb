require "spec_helper"
require "brut/cli"
require "stringio"

RSpec.describe Brut::CLI::Commands::OutputError do


  it "prints an exception to stderr" do
    exception = nil
    begin
      raise "OH NOES!"
    rescue => ex
      exception = ex
    end
    stderr = StringIO.new
    command = described_class.new(exception)

    exit_code = command.execute(Brut::CLI::Commands::ExecutionContext.new(stderr:))
    expect(exit_code).to eq(65)
    expect(stderr.string).to eq("OH NOES!\n")
  end

  it "does not want bootsrapping" do
    command = described_class.new(StandardError.new)
    expect(command.bootstrap?).to eq(false)
  end

  it "does not set a project environment" do
    command = described_class.new(StandardError.new)
    expect(command.default_rack_env).to eq(nil)
  end

end
