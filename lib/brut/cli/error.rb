# All errors from a Brut CLI should extend this.  Any error that does will be caught and handled without showing the user a stack
# trace.
class Brut::CLI::Error < StandardError
end
# Called when a child process executed by {Brut::CLI::Executor} returns a nonzero exit status.
#
# @see Brut::CLI::Executor#system!
class Brut::CLI::SystemExecError < Brut::CLI::Error
  # @return [String|Array] command line invocation that caused the error
  attr_reader :command
  # @return [Integer] exit status of the command
  attr_reader :exit_status
  # @param [String|Array] command or args passed to {Brut::CLI::Executor#system!}.
  # @param [Integer] exit_status the exit status of the command.
  def initialize(command,exit_status)
    super("#{command} failed - exited #{exit_status}")
    @command = command
    @exit_status = exit_status
  end
end
