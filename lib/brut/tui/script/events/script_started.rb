# Fired when the script is just starting
class Brut::TUI::Script::Events::ScriptStarted < Brut::TUI::Events::BaseEvent
  def initialize(phases:)
    @phases = phases
  end
  # Adds `phases` as an array of `[description,Proc]` representing the phases.
  # You are discouraged from interacting with the `Proc` objects.
  def deconstruct_keys(keys=nil)
    super.merge({ phases: @phases })
  end 
  def to_s = "Starting"
end
