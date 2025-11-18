# A subscriber that uses Ruby's logger to log messages.
# The purpose of this is to ensure that every bit of available information about
# a `Script` is placed somewhere for later review. This allows any output to the terminal
# to be more brief or user-friendly without losing information.
class Brut::TUI::Script::LoggingSubscriber
  def initialize(progname, logfile:)
    @logger = Logger.new(logfile, progname:)
    @logger.formatter = proc { |severity, time, progname, msg|
      "#{time} - [ #{progname} ] #{severity}: #{strip_ansi(msg)}\n"
    }
    @stdout = {}
    @stderr = {}
  end

  def on_event_loop_started(event)
    @logger.debug("TUI Event loop started")
  end

  def on_exception(event)
    @logger.error("#{event.exit? ? 'FATAL' : 'non-fatal'} ExceptionEvent: #{event.exception.class}: #{event.exception.message}\n    #{event.exception.backtrace.join("\n    ")}")
  end

  def on_executing_command(command:)
    @logger.info("Executing command `#{command}`")
    @stdout[command] = ''
    @stderr[command] = ''
  end

  def on_command_std_out(command:, output:)
    @stdout[command] << output
  end

  def on_command_std_err(command:, output:)
    @stderr[command] << output
  end

  def on_command_execution_succeeded(command:)
    if !@stdout[command].empty?
      @logger.info("\n#{strip_ansi(@stdout[command])}")
    end
    if !@stderr[command].empty?
      @logger.warn("\n#{strip_ansi(@stderr[command])}")
    end
    @logger.info("Command `#{command}` executed successfully.")
  end

  def on_command_execution_failed(command:)
    if !@stdout[command].empty?
      @logger.info("\n#{strip_ansi(@stdout[command])}")
    end
    if !@stderr[command].empty?
      @logger.warn("\n#{strip_ansi(@stderr[command])}")
    end
    @logger.error("Command `#{command}` failed.")
    raise "DOH"
  end

  def on_model_updated(*)
  end

  def on_tick(*)
  end

  def on_script_completed(*)
  end

  def on_script_started(*)
  end

  def on_any_event(event)
    case event
    in { description: }
      @logger.info(description)
    in { message:, type: :warning }
      @logger.warn(message)
    in { message:, type: :error }
      @logger.error(message)
    in { message: }
      @logger.info(message)
    in { handler_method_name: }
      @logger.info(handler_method_name)
    else
      @logger.info(event.to_s)
    end
  end
private

  ANSI_ESCAPE = %r{ 
    \e\[[@-Z\\-_] |           # 1-byte sequences
    \e\[[0-?]*[ -\/]*[@-~] |  # CSI sequences
    \e\][^\a]*\a |            # OSC sequences
    \eP[^\a]*\a |             # DCS
    \e_[^\a]*\a |             # APC
    \e\^[^\a]*\a              # PM
  }x

  def strip_ansi(string) = string.gsub(ANSI_ESCAPE, '')
end
