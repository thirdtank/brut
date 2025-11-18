module SpecSupport
  class TestEvent < Brut::TUI::Events::BaseEvent
    def self.handler_method_name = :on_test_event
  end
end
