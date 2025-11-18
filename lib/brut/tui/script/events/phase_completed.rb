# Fired when a phase completes
class Brut::TUI::Script::Events::PhaseCompleted < Brut::TUI::Script::Events::PhaseStarted
  def to_s = "#{@name} completed"
end
