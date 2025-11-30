class Brut::TUI::Events
  autoload(:BaseEvent, "brut/tui/events/base_event")
  autoload(:EventLoopStarted, "brut/tui/events/event_loop_started")
  autoload(:Exception, "brut/tui/events/exception")
  autoload(:EventBus, "brut/tui/events/event_bus")
  autoload(:Tick, "brut/tui/events/tick")
end
