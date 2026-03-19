module Brut::CLI::Commands
  autoload(:BaseCommand, "brut/cli/commands/base_command")
  autoload(:CompoundCommand, "brut/cli/commands/compound_command")
  autoload(:Help, "brut/cli/commands/help")
  autoload(:HelpInMarkdown, "brut/cli/commands/help_in_markdown")
  autoload(:OutputError, "brut/cli/commands/output_error")
  autoload(:RaiseError, "brut/cli/commands/raise_error")
  autoload(:ExecutionContext, "brut/cli/commands/execution_context")
end
