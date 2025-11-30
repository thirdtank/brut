# Fired when a command is executed (this also serves as a base class for the results
# of such execution).
class Brut::TUI::Script::Events::ExecutingCommand < Brut::TUI::Events::BaseEvent
  def initialize(step:)
    @step = step
  end

  # Includes `description` and `command` in the keyword arguments
  def deconstruct_keys(keys=nil)
    super.merge({ description: @step.description, command: @step.command })
  end
end
