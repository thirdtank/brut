# Fired when a subcommand exited nonzero
class Brut::TUI::Script::Events::CommandExecutionFailed < Brut::TUI::Script::Events::ExecutingCommand
  def exit? = true
end
