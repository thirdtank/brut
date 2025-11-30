# Indicates that the loop has started. In general, this is the first event
# that will be fired for any TUI.
class Brut::TUI::Events::EventLoopStarted < Brut::TUI::Events::BaseEvent
  def to_s = "EventLoopStarted"
end
