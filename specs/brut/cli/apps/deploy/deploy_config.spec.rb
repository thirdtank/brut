require "spec_helper"

RSpec.describe Brut::CLI::Apps::Deploy::DeployConfig do
  it "defaults to include web" do
    config = described_class.new
    expect(config.processes.size).to eq(1)
    expect(config.processes[0].cmd_directive).to eq("CMD [ \"bundle\", \"exec\", \"bin/run\" ]")
  end
end
