require "spec_helper"
require "brut/cli"
require "stringio"

RSpec.describe Brut::CLI::Commands::RaiseError do

  let(:stdout) { StringIO.new }
  let(:stderr) { StringIO.new }
  let(:stdin)  { StringIO.new }

  it "raises the exception" do
    exception = nil
    begin
      raise "OH NOES!"
    rescue => ex
      exception = ex
    end
    command = described_class.new(exception)

    expect {
      command.run
    }.to raise_error(exception)
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
