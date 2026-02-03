require "logger"
require "fileutils"
require "delegate"

class Brut::CLI::Logger < SimpleDelegator
  def initialize(app_name:, stdout:, stderr:)
    @app_name = app_name
    @stdout   = stdout
    @logger   = ::Logger.new("/dev/null")

    super(@logger)

    @simple_formatter =  ->(_severity, _time, progname, msg) {
      "[ #{progname} ] #{msg}\n"
    }
    @file_formatter =  ->(severity, time, _progname, msg) {
      "#{time} - [#{severity}] #{msg}\n"
    }

    @stdout_logger = ::Logger.new("/dev/null")
    @stderr_logger = if stderr.nil? 
                       ::Logger.new("/dev/null")
                     else
                       ::Logger.new(stderr, progname: @app_name, formatter: @simple_formatter)
                     end

    @log_file = nil
  end

  def level=(level)
    if level
      @logger.level = level
      @stdout_logger.level = level
      @stderr_logger.level = level
    end
  end

  def log_file=(log_file)
    @log_file = log_file
    if log_file
      log_dir = log_file.dirname
      if !log_dir.exist?
        FileUtils.mkdir_p(log_dir)
      end
      @logger = ::Logger.new(@log_file, formatter: @file_formatter, progname: @app_name, level: @logger.level)
      __setobj__(@logger)
      if @logger.level == ::Logger::DEBUG
        @stdout.puts "Logging to file #{@log_file}"
      end
    end
  end

  def log_to_stdout=(log_to_stdout)
    @log_to_stdout = log_to_stdout
    if @log_to_stdout
      @stdout_logger = ::Logger.new(@stdout, formatter: @simple_formatter, progname: @app_name, level: @logger.level)
    else
      @stdout_logger = ::Logger.new("/dev/null")
    end
  end
  def debug(message=nil,&block)
    @logger.debug(message,&block)
    @stdout_logger.debug(message,&block)
  end
  def info(message=nil,&block)
    @logger.info(message,&block)
    @stdout_logger.info(message,&block)
  end
  def warn(message=nil,&block)
    @logger.warn(message,&block)
    @stdout_logger.warn(message,&block)
    @stderr_logger.warn(message,&block)
  end
  def error(message=nil,&block)
    @logger.error(message,&block)
    @stdout_logger.error(message,&block)
    @stderr_logger.error(message,&block)
  end
  def fatal(message=nil,&block)
    @logger.fatal(message,&block)
    @stdout_logger.fatal(message,&block)
    @stderr_logger.fatal(message,&block)
  end

  def without_stderr
    logger = self.class.new(app_name: @app_name, stdout: @stdout, stderr: nil)
    logger.level = @logger.level
    logger.log_file = @log_file
    logger.log_to_stdout = @log_to_stdout
    logger
  end
end
