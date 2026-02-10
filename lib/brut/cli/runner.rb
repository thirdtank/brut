# Runs a CLI app/command.  Handles all the logic of parsing command line arguments, locating
# the command object to process the execution, allow for help requests, and understanding the output.
class Brut::CLI::Runner

  # Create the runner, which can be used to run `app_command` with whatever command line was provided.
  #
  # @param [Brut::CLI::Commands::BaseCommand] app_command The app that is being executed, in which all command line arguments
  #        should be interpreted.
  # @param [IO] stdout the standard output, which will receive all output that isn't related to error messages.
  # @param [IO] stderr the standard error, which will receive error messages
  # @param [IO] stdin the standard input
  # @param [Pathname] project_root root of the Brut project (i.e. where `Gemfile`, `app` et. al. are located)
  def initialize(app_command, stdout:, stderr:,stdin:, project_root:)
    @app_name = if $0 =~ /\/brut$/
                  "brut #{app_command.name}"
                else
                  $0
                end
    @app_command  = app_command
    @stdout       = stdout
    @stderr       = stderr
    @stdin        = stdin
    @project_root = project_root
  end


  # Run the commmand or subcommand based on the `app_command` given to the constructor and the command line
  # provided in `argv`.
  #
  # @param [Array] argv The arguments provided to the command. Outside of tests, this is almost certainly `ARGV`.
  # @param [ENV|Hash] env The UNIX environment available when the command was executed.  This should be treated
  #        as if it's `ENV`, even though it may just be a hash.
  # @return [Integer] the exit code to pass back to the shell that invoked the command, with 0 meaning the 
  #         command succeeded and any other value meaning failure.  Generally, this value should be between 0 and 255.
  def run!(argv, env)

    parsed_command_line = Brut::CLI::ParsedCommandLine.new(app_command: @app_command, argv:, env:)

    logger = Brut::CLI::Logger.new(
      app_name: @app_command.name,
      stdout: @stdout,
      stderr: @stderr,
      theme: parsed_command_line.command.theme,
    )

    load_unix_environment!(env, parsed_command_line)
    setup_log_level(env, parsed_command_line)
    bootstrap!(env, parsed_command_line)

    execute_result = Brut::CLI::ExecuteResult.new do
      execution_context = Brut::CLI::Commands::ExecutionContext.new(
        argv: parsed_command_line.argv,
        options: Brut::CLI::Options.new(parsed_command_line.options),
        env:,
        stdout: @stdout,
        stderr: @stderr,
        stdin: @stdin,
        logger:
      )
      parsed_command_line.command.execute(execution_context)
    end
    execute_result.exit_status do |error_message|
      logger.fatal(error_message)
      @stderr.puts error_message
      if parsed_command_line.options.log_file && !parsed_command_line.options.log_stdout?
        @stderr.puts
        @stderr.puts "More details may be available from the log file:"
        @stderr.puts
        @stderr.puts "    " + parsed_command_line.options.log_file.to_s
        @stderr.puts
        @stderr.puts "You can also use --log-stdout to see these log messages in the terminal"
      end

    end
  end

private

  def load_unix_environment!(env, parsed_command_line)
    if env["RACK_ENV"]
      if parsed_command_line.project_environment
        @stderr.puts "RACK_ENV is set in the environment, which supercedes the command line, --env ignored"
      end
    else
      env["RACK_ENV"] = if parsed_command_line.project_environment
                          parsed_command_line.project_environment.to_s
                        else
                          parsed_command_line.command.default_rack_env
                        end
    end

    rack_env = RichString.from_string(env["RACK_ENV"])

    if !rack_env
      return
    end
    require "bundler"
    if rack_env == "production"
      Bundler.setup(:default)
      Bundler.require(:default)
      return
    end

    Bundler.setup(:default, rack_env.to_sym)
    Bundler.require(:default, rack_env.to_sym)

    require "dotenv"

    Dotenv.load(@project_root / ".env.#{rack_env}.local",
                @project_root / ".env.#{rack_env}")

    if env != ENV
      # To prevent us from having to depend directly on ENV, we want everything
      # to use env, however Dotenv doesn't allow this and just populates ENV,
      # so we want to copy everything over.
      ENV.each do |key, value|
        # Do not allow Dotenv to ovrerwrite RACK_ENV, since that is what we used
        # to load these files in the first place.
        if key != "RACK_ENV"
          env[key] = value
        end
      end
    end
  end

  def setup_log_level(env, parsed_command_line)
    if env["LOG_LEVEL"]
      @stderr.puts "LOG_LEVEL is set in the environment, which supercedes the command line, --log-level ignored"
    elsif parsed_command_line.options.log_level?
      env["LOG_LEVEL"] = parsed_command_line.options.log_level
    end
  end

  def bootstrap!(env, parsed_command_line)
    if env["RACK_ENV"]
      log_level = env["LOG_LEVEL"]

      if !parsed_command_line.options.verbose? && !parsed_command_line.options.debug?
        env["LOG_LEVEL"] = "warn"
      end

      require "#{@project_root}/app/bootstrap"
      bootstrap = Bootstrap.new
      if parsed_command_line.command.bootstrap?
        bootstrap.bootstrap!
      else
        bootstrap.configure_only!
      end

      env["LOG_LEVEL"] = log_level
    end
  end
end
