require "open3"

# A step whose behavior is to run a command as a child process.
# Fires {Brut::TUI::Script::Events::StepStarted} then
# {Brut::TUI::Script::Events::ExecutingCommand} before the command is run.
# The command is then run with `Open3.popen3` and the stderr and stdout
# are streamed as output is available. Each block of bytes read
# generates a {Brut::TUI::Script::Events::CommandStdOut}
# or a {Brut::TUI::Script::Events::CommandStdErr} event with 
# the bytes reads.
#
# If the command exited nonzero, 
# {Brut::TUI::Script::Events::CommandExecutionSucceeded} is fired,
# otherwise {Brut::TUI::Script::Events::CommandExecutionFailed} is fired,
# Either way, {Brut::TUI::Script::Events::StepCompleted} is fired
# *unless* there is an unhandled exception.
class Brut::TUI::Script::ExecStep < Brut::TUI::Script::Step

  attr_reader :command
  def initialize(event_loop, description, command:, stdout: false, stderr: false)
    super(event_loop, description)
    @command = command
    @stdout  = stdout
    @stderr  = stderr
  end

  def deconstruct_keys(keys=nil)
    super.deconstruct_keys(keys).merge({
      command: @command,
      strip_ansi: false,
      stdout: @stdout,
      stderr: @stderr,
    })
  end
  def run!
    event_loop << Events::StepStarted.new(step: self)
    event_loop << Events::ExecutingCommand.new(step: self)

    wait_thread = Open3.popen3(*@command) do |_stdin,stdout,stderr,wait_thread|
      o = stdout.read_nonblock(10, exception: false)
      e = stderr.read_nonblock(10, exception: false)
      while o || e
        if o
          if o != :wait_readable
            event_loop << Events::CommandStdOut.new(step: self, output: o, show: @stdout)
          end
          o = stdout.read_nonblock(10, exception: false)
        end
        if e
          if e != :wait_readable
            event_loop << Events::CommandStdErr.new(step: self, output: e, show: @stderr)
          end
          e = stderr.read_nonblock(10, exception: false)
        end
      end
      wait_thread
    end

    if wait_thread.value.success?
      event_loop << Events::CommandExecutionSucceeded.new(step: self)
    else
      event_loop << Events::CommandExecutionFailed.new(step: self)
    end
    event_loop << Events::StepCompleted.new(step: self)
  end
end

