require "spec_helper"
require "brut/tui"

RSpec.describe Brut::TUI::Events::Exception do

  describe ":#exit?" do
    it "is true" do
      event = described_class.new(StandardError.new("Test exception"))
      expect(event.exit?).to eq(true)
    end
  end
  describe ":#drain_then_exit?" do
    it "is false" do
      event = described_class.new(StandardError.new("Test exception"))
      expect(event.drain_then_exit?).to eq(false)
    end
  end

end
