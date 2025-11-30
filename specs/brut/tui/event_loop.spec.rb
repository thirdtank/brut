require "spec_helper"
require "brut/tui"

RSpec.describe Brut::TUI::EventLoop do
  subject(:event_loop) { described_class.new(tick: false) }

  class ExitEvent < Brut::TUI::Events::BaseEvent
    def exit? = true
  end

  class RaiseExceptionEvent < Brut::TUI::Events::BaseEvent
    def initialize(message)
      @message = message
    end
    def raise_exception!
      raise StandardError.new(@message)
    end
  end

  class GeneralSubscriber
    attr_reader :events
    def initialize
      @events = []
    end
    def on_any_event(event)
      if event.respond_to?(:raise_exception!)
        event.raise_exception!
      else
        @events << event
      end
    end
  end

  it "stops the loop when an event returns true for exit?" do
    main_thread = Thread.new {
      event_loop.run
    }
    event_loop << ExitEvent.new
    main_thread.join(0.1)
    expect(main_thread.alive?).to eq(false)
  end

  def start_loop(event_loop, wait_time: 0.1)
    exception = nil
    main_thread = Thread.new {
      begin
      event_loop.run
      rescue => ex
        exception = ex
      end
    }
    main_thread.join(wait_time)
    expect(exception).to eq(nil)
  end

  it "fires the event LoopStarted event when run" do
    general_subscriber = GeneralSubscriber.new
    event_loop.subscribe_to_all(general_subscriber)
    start_loop(event_loop)
    expect(general_subscriber.events[0].class).to eq(Brut::TUI::Events::EventLoopStarted)
  end

  it "fires exception events when errors are raised" do
    general_subscriber = GeneralSubscriber.new
    event_loop.subscribe_to_all(general_subscriber)
    event_loop << RaiseExceptionEvent.new("Test exception")
    start_loop(event_loop)
    expect(general_subscriber.events[1].class).to eq(Brut::TUI::Events::Exception)
  end
end
