# A subscriber that attempts to provide a user-friend, brief, summarized, fancy
# output for the script that is running.  It is intended to show you
# what's happening at a high level, but deferring all details (like child process
# output) to the {Brut::TUI::Script::LoggingSubscriber}'s log file.
class Brut::TUI::Script::PutsSubscriber
  def initialize(progname, terminal:, theme:, stdout: false, stderr: false)
    @progname      = progname
    @terminal      = terminal
    @theme         = theme
    @prefix_recent = false
    @stdout        = stdout
    @stderr        = stderr
    @stdout_buffer = {}
    @stderr_buffer = {}
    @step_indent   = "Phase 1/1 ".length
  end

  def on_phase_started(description:, step_number:, total_steps:)
    total_format_string = if total_steps < 10
                            "%1d"
                          else
                            "%2d"
                          end
    preamble = sprintf("Phase %d/#{total_format_string}", step_number, total_steps)
    @step_indent = preamble.length + 1
    println @theme.reset + @theme.bold + preamble + @theme.reset + " " + @theme.with_markup(description, text: :heading)
  end

  def on_step_started(description:)
    println @theme.with_markup(description), step_indent: true
  end

  def on_executing_command(command:)
    println @theme.with_markup("> `#{command}`"), step_indent: true
    $stdout.print @theme.reset
    @stdout_buffer[command] = ""
    @stderr_buffer[command] = ""
  end

  def on_command_execution_failed(command:)
    println @theme.with_markup("FAILED", text: :error), step_indent: true
    if !@stdout
      println ""
      println @stdout_buffer[command] + "\n"
    end
    if !@stderr
      println ""
      println @theme.warning + @stderr_buffer[command]
    end

  end

  def on_exception(exception:)
    println @theme.error + "Exception: #{exception.class}: #{exception.message}\n    #{exception.backtrace.join("\n    ")}"
  end

  def on_command_std_out(output:, command:)
    if @stdout
      @prefix_recent = false
      $stdout.print @theme.normal + @theme.weak + output + @theme.reset
      $stdout.flush
    else
      @stdout_buffer[command] << output
    end
  end

  def on_command_std_err(output:, command:)
    if @stderr
      @prefix_recent = false
      $stdout.print @theme.warning + output + @theme.reset
      $stdout.flush
    else
      @stderr_buffer[command] << output
    end
  end

  def on_command_execution_succeeded(command:)
    println @theme.with_markup("✅", text: :success), step_indent: true
  end

  def on_message(message:, type:)
    if type == :done
      println @theme.with_markup(message, text: :success)
    else
      println @theme.with_markup(message, text: type), step_indent: true
    end
  end


private

  def prefix_string = "[ #{@progname} ] "

  def step_indent = @step_indent

  def println(message, step_indent: false)
    @terminal.io.puts prefix + (step_indent ? " " * self.step_indent : "") + message
  end

  def prefix
    if @prefix_recent
      @theme.italic + @theme.weak + prefix_string + @theme.weak_off + @theme.italic_off
    else
      @prefix_recent = true
      prefix_string
    end
  end
end

