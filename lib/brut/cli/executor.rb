require "open3"
# Abstracts the invocation of child processes, but includes useful output and exception handling that you'd need to be transparent to
# the user.  In particular:
#
# * Outputs the command being executed to the standard error (via {Brut::CLI::Output}).
# * Outputs the command's standard error and standard output in real time.  So, this should be usable for spawned commands that
# produce real time output like test runners.
# * Assumes spawned commands should succeed, raising an error if they do not.
class Brut::CLI::Executor
  # Create the executor
  #
  # @param [Brut::CLI::Output] out an IO used to send messages to the standard output
  # @param [Brut::CLI::Output] err an IO used to send messages to the standard error
  def initialize(out:,err:)
    @out = out
    @err = err
  end

  # Execute a command, logging it to the standard output and outputing the 
  # commands output and error to the standard output and error, respectively. If 
  # the command exits nonzero, the exit status is returned.
  #
  # Generally, you want to use {#system!} for commands that must succeed
  # for the caller to continue.  Only use this method if you need 
  # to do special error-handling when the underlying command fails.
  #
  # @see https://docs.ruby-lang.org/en/3.3/Open3.html#method-c-popen3
  # @see {#system!}
  #
  # @param [String|Array] args Whatever you would give to `Kernel#system` or `Open3.popen3`.
  # @return [int] 0 if the command completed normally, otherwise the nonzero exit status. **DO NOT TREAT THIS AS A BOOLEAN VALUE**
  def system(*args)
    self.system!(*args)
    0
  rescue Brut::CLI::SystemExecError => e
    e.exit_status
  end

  # Execute a command, logging it to the standard output and outputing the 
  # commands output and error to the standard output and error, respectively. If 
  # the command exits nonzero, an exception is raised and your CLI app will
  # also exit nonzero.
  #
  # If you need to handle  the command exiting nonzero, use {#system}
  # instead, as it will not raise an exception.
  #
  # @see https://docs.ruby-lang.org/en/3.3/Open3.html#method-c-popen3
  # @see {#system}
  #
  # @param [String|Array] args Whatever you would give to `Kernel#system` or `Open3.popen3`.
  # @raise Brut::CLI::Error::SystemExecError if the spawed command exits nonzero
  # @return [int] Always returns 0
  def system!(*args)
    @out.puts "Executing #{args}"
    wait_thread = Open3.popen3(*args) do |_stdin,stdout,stderr,wait_thread|
      o = stdout.read_nonblock(10, exception: false)
      e = stderr.read_nonblock(10, exception: false)
      while o || e
        if o
          if o != :wait_readable
            @out.print o
            @out.flush
          end
          o = stdout.read_nonblock(10, exception: false)
        end
        if e
          if e != :wait_readable
            @err.print e
            @err.flush
          end
          e = stderr.read_nonblock(10, exception: false)
        end
      end
      wait_thread
    end
    if wait_thread.value.success?
      @out.puts "#{args} succeeded"
    else
      raise Brut::CLI::SystemExecError.new(args,wait_thread.value.exitstatus)
    end
    0
  end
end
