# Fired when the script has completed
class Brut::TUI::Script::Events::ScriptCompleted < Brut::TUI::Events::BaseEvent
  def drain_then_exit? = true
  def to_s = "Done"
end
