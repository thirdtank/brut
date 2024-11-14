# Marker that means an expected error happens and
# we don't need to show the stack trace
class Brut::CLI::Error < StandardError
end
class Brut::CLI::SystemExecError < Brut::CLI::Error
  attr_reader :command,:exit_status
  def initialize(command,exit_status)
    super("#{command} failed - exited #{exit_status}")
    @command = command
    @exit_status = exit_status
  end
end
