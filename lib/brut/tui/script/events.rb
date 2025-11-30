module Brut::TUI::Script::Events
  autoload :ScriptStarted  , "brut/tui/script/events/script_started"
  autoload :ScriptCompleted , "brut/tui/script/events/script_completed"
  autoload :PhaseStarted   , "brut/tui/script/events/phase_started"
  autoload :PhaseCompleted , "brut/tui/script/events/phase_completed"
  autoload :StepStarted   , "brut/tui/script/events/step_started"
  autoload :StepCompleted , "brut/tui/script/events/step_completed"
  autoload :ExecutingCommand , "brut/tui/script/events/executing_command"
  autoload :CommandStdOut, "brut/tui/script/events/command_std_out"
  autoload :CommandStdErr, "brut/tui/script/events/command_std_err"
  autoload :CommandExecutionSucceeded , "brut/tui/script/events/command_execution_succeeded"
  autoload :CommandExecutionFailed , "brut/tui/script/events/command_execution_failed"
  autoload :Message , "brut/tui/script/events/message"
end
