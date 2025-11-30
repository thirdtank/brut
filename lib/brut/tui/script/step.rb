# Base class for specific types of steps
class Brut::TUI::Script::Step

  Events = Brut::TUI::Script::Events

  attr_reader :description
  def initialize(event_loop, description, exec: nil, &block)
    @event_loop = event_loop
    @description = description
  end

  private attr_reader :event_loop
end
