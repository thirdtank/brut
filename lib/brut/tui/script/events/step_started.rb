# Fired when a step is about to execute
class Brut::TUI::Script::Events::StepStarted < Brut::TUI::Events::BaseEvent
  def initialize(step:)
    @step = step
  end

  # Adds `description` to the keyword arguments
  def deconstruct_keys(keys=nil)
    super.merge({ description: @step.description })
  end
  def to_s = @description
end
