require "spec_helper"
require "brut/tui"
require_relative "test_event"

RSpec.describe Brut::TUI::Events::EventBus do
  class OtherTestEvent < Brut::TUI::Events::BaseEvent
    def self.handler_method_name
      :on_other_test_event
    end
  end

  class SubscriberToTestEvent
    def notified = @notified
    def notified_method = @notified_method
    def on_test_event(event)
      @notified = event
      @notified_method = :on_test_event
    end
  end
  class SubscriberToAnyEventOnly
    def notified = @notified
    def notified_method = @notified_method
    def on_any_event(event)
      @notified = event
      @notified_method = :on_any_event
    end
  end
  class SubscriberToTestEventAndAnyEvent
    def notified = @notified
    def notified_method = @notified_method
    def on_test_event(event)
      @notified = event
      @notified_method = :on_test_event
    end
    def on_any_event(event)
      @notified = event
      @notified_method = :on_any_event
    end
  end

  class RaisesErrorInTestEvent
    def on_test_event(event)
      raise "Error in on_test_event"
    end
  end

  class RaisesErrorInAnyEvent
    def on_any_event(event)
      raise "Error in on_any_event"
    end
  end

  subject(:event_bus) { described_class.new }

  describe "#subscribe" do
    context "subscriber implements the handler method" do
      it "is notified" do
        subscriber = SubscriberToTestEvent.new
        event_bus.subscribe(SpecSupport::TestEvent, subscriber)
        event = SpecSupport::TestEvent.new

        errors = event_bus.notify(event)

        expect(errors).to                     eq([])
        expect(subscriber.notified).to        eq(event)
        expect(subscriber.notified_method).to eq(:on_test_event)
      end
    end
    context "subscriber does not implement the handler method" do
      it "is raises when subscribing" do
        subscriber = SubscriberToAnyEventOnly.new
        expect {
          event_bus.subscribe(SpecSupport::TestEvent, subscriber)
        }.to raise_error(ArgumentError, /does not implement handler method/)
      end
    end
  end
  describe "#subscribe_to_all" do
    context "subscriber implements the handler method" do
      it "is notified via that method" do
        subscriber = SubscriberToTestEventAndAnyEvent.new
        event_bus.subscribe_to_all(subscriber)
        event = SpecSupport::TestEvent.new

        errors = event_bus.notify(event)

        expect(errors).to                     eq([])
        expect(subscriber.notified).to        eq(event)
        expect(subscriber.notified_method).to eq(:on_test_event)
      end
    end
    context "subscriber does not implement the handler method" do
      context "subscriber implements on_any_event" do
        it "calls on_any_event when notified" do
          subscriber = SubscriberToAnyEventOnly.new
          event_bus.subscribe_to_all(subscriber)
          event = SpecSupport::TestEvent.new

          errors = event_bus.notify(event)

          expect(errors).to                     eq([])
          expect(subscriber.notified).to        eq(event)
          expect(subscriber.notified_method).to eq(:on_any_event)
        end
      end
      context "subscriber does not implement on_any_event" do
        it "nothing happens" do
          subscriber = SubscriberToTestEvent.new
          event_bus.subscribe_to_all(subscriber)
          event = OtherTestEvent.new

          errors = event_bus.notify(event)

          expect(errors).to                     eq([])
          expect(subscriber.notified).to        eq(nil)
          expect(subscriber.notified_method).to eq(nil)
        end
      end
    end
  end
  describe "#notify" do

    # some of this method's behavior is covered by the tests above
    
    context "when subscribers raise errors" do
      it "returns them as an array" do
        event_bus.subscribe(SpecSupport::TestEvent, RaisesErrorInTestEvent.new)
        event_bus.subscribe_to_all(RaisesErrorInAnyEvent.new)
        event_bus.subscribe_to_all(SubscriberToAnyEventOnly.new)

        event = SpecSupport::TestEvent.new

        errors = event_bus.notify(event)

        expect(errors.length).to         eq(2)
        expect(errors.map(&:message)).to include("Error in on_test_event")
        expect(errors.map(&:message)).to include("Error in on_any_event")
      end
    end
  end
end
