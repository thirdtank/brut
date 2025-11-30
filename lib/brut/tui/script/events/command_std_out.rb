# Fired when a command has provided at least some output on its standard output.
class Brut::TUI::Script::Events::CommandStdOut < Brut::TUI::Events::BaseEvent
  def initialize(step:, output:)
    @step   = step
    @output = output
  end

  # Adds `description`, `command` and `output` to the event keywords. `output` is a string
  # containing whatever output was available. This is likely not terminated with a newline.
  def deconstruct_keys(keys=nil)
    super.merge({ description: @step.description, command: @step.command, output: @output })
  end
end
