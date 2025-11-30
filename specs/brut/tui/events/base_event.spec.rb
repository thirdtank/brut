require "spec_helper"
require "brut/tui"

RSpec.describe Brut::TUI::Events::BaseEvent do
  class TestEvent < Brut::TUI::Events::BaseEvent; end
  module Deeply
    module Nested
      class TestEvent < Brut::TUI::Events::BaseEvent; end
    end
  end

  describe ".handler_method_name" do
    it "returns the underscorized simple class name prefixed with 'on_'" do

      expect(TestEvent.handler_method_name).to eq("on_test_event")
      expect(Deeply::Nested::TestEvent.handler_method_name).to eq("on_test_event")
    end
  end

  describe "#exit?" do
    it "returns false by default" do
      event = Brut::TUI::Events::BaseEvent.new
      expect(event.exit?).to be false
    end
  end
end
