# A command that exists only to call other commands in order.  This is useful if you want
# a convienience command to call two or more other commands.  By default, each command
# must succeed for the others to be called.
class Brut::CLI::Commands::CompoundCommand < Brut::CLI::Commands::BaseCommand
  # Create the compound command with the given list of commands.  Note that these
  # commands will be executed with *this* commands `Brut::CLI::Commands::ExecutionContext`, so these commands
  # should all be able to work with whatever command line arguments and `argv` would be provided.
  def initialize(commands)
    @commands = commands
  end

  # Overrides the parent class to call each command in order. Note that if you subclass this class, **`run` is
  # not called**. If you want to perform custom logic, you must override this method, but take care to call
  # methods on the passed `execution_context`.  Methods like `puts`, `system!`, and `options` **will not work** here
  # since they assume an ivar named `@execution_context` has been set.
  def execute(execution_context)
    @commands.each do |command|
      execute_result = Brut::CLI::ExecuteResult.new do
        command.execute(execution_context)
      end
      if execute_result.failed?
        return execute_result.exit_status do |error_message|
          @stderr.puts error_message
        end
      end
    end
    0
  end
end
