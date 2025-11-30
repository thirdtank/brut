# Fired when a phase starts, but before any steps have executed
class Brut::TUI::Script::Events::PhaseStarted < Brut::TUI::Events::BaseEvent
  def initialize(description, step_number:, total_steps:)
    @description = description
    @step_number = step_number
    @total_steps = total_steps
  end

  # Adds `description`, `step_number` (1-based), and `total_steps` to the keyword arguments.
  def deconstruct_keys(keys=nil)
    super.merge({ description: @description, step_number: @step_number, total_steps: @total_steps })
  end
  def to_s = @description
end
