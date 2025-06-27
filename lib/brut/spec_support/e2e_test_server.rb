require "socket"
require "timeout"

# Manages running the app in test mode for the purposes of running End-to-End tests against it.
class Brut::SpecSupport::E2ETestServer
  include SemanticLogger::Loggable
  def self.instance
    @instance ||= self.new(bin_dir: Brut.container.project_root / "bin")
  end

  # Create the test server, which will run various Brut dev commands
  # from the given bin dir
  #
  # @param [Pathname] bin_dir path to where the app's Brut-provide CLI apps are installed
  def initialize(bin_dir:)
    @bin_dir = bin_dir
    @pid     = nil
  end

  # Starts the server. Returns when the server has started
  def start
    if !@pid.nil?
      logger.warn "Server is already running on pid '#{@pid}'"
      return
    end
    Bundler.with_unbundled_env do
      command = "#{@bin_dir}/test-server"
      logger.info "Starting test server via '#{command}'"
      @pid = Process.spawn(
        command,
        pgroup: true # We want this in its own process group, so we can 
                     # more reliably kill it later on
      )
      logger.info "Starting with pid '#{@pid}'"
    end
    if is_port_open?("0.0.0.0",6503)
      logger.info "Server is listening for requests on port 6503"
    else
      raise "Problem: server never started"
    end
  end

  # Stops the server
  def stop
    if @pid.nil?
      logger.warn "Server is already stopped"
      return
    end
    logger.info "Stopping server nicely with TERM of pid '#{@pid}'"
    Process.kill("-TERM",@pid) # The '-' is to kill the process group, not just the pid
    begin
      Timeout.timeout(4) do
        Process.wait(@pid)
      end
    rescue Timeout::Error
      logger.warn "Server still active after 4 seconds. Trying KILL on pid '#{@pid}'"
      Process.kill("-KILL",@pid)
    end
    @pid = nil
  end

private

  def is_port_open?(ip, port)
    begin
      Timeout::timeout(5) do
        loop do
          begin
            logger.debug "Attemping to conenct to '#{ip}' on port '#{port}'"
            s = TCPSocket.new(ip, port)
            s.close
            logger.debug "Connection accepted - server should be up!"
            return true
          rescue Errno::ECONNREFUSED, Errno::EHOSTUNREACH
            logger.debug "Connection refused - server must still be starting"
            sleep(0.1)
          end
        end
      rescue Timeout::Error
      end
      false
    end
  end
end

