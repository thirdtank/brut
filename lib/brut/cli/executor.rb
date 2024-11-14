require "open3"
class Brut::CLI::Executor
  def initialize(out:,err:)
    @out = out
    @err = err
  end
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
      raise Brut::CLI::SystemExecError.new(*args,wait_thread.value.exitstatus)
    end
    true
  end
end
