require "optparse"
require "pathname"
require "brut/framework/project_environment"

# Parses the command line and makes everything parsed available as attributes.
class Brut::CLI::ParsedCommandLine

  # The command that should be executed based on what was parsed from the command line
  #
  # @return [Brut::CLI::Commands::BaseCommand]
  attr_reader :command

  # The remaining unparsed command line arguments.
  #
  # @return [Array<String>]
  attr_reader :argv

  # The parsed command line switches and flags.
  #
  # @return [Brut::CLI::Options]
  attr_reader :options

  # The project enviornment, if specified
  # @return [Brut::Framework::ProjectEnvironment]
  attr_reader :project_environment

  # Create the ParsedCommandLine based on a base command (which provides the initial set of 
  # command line options), the ARGV and the ENV when the command was invoked.
  #
  # This should always succeed, however depending on the contents of the parameters, the value
  # for `#command` may be a command that outputs an error.
  def initialize(app_command:, argv:, env:)
    brut_provided_help_requested = false
    app_option_parser = new_option_parser(app_command.name) do |opts|
      opts.banner = app_command.description
      app_command.accepts.each_with_index { |class_or_class_and_proc,index| accept(opts,class_or_class_and_proc,index) }
      app_command.opts.each do |option|
        opts.on(*option)
      end
      opts.on("--help", "-h", "Show help") do
        brut_provided_help_requested = true
      end
    end

    options = {}
    remaining_argv = app_option_parser.order!(argv,into: options)

    if remaining_argv[0] == "help"
      brut_provided_help_requested = true
      remaining_argv.shift
    end

    help_command = if brut_provided_help_requested
                     Brut::CLI::Commands::Help.new(app_command,app_option_parser)
                   end

    command = app_command
    loop do
      arg = remaining_argv.shift
      command_found = command.commands.detect { it.name == arg }
      if command_found
        command_found.parent_command = command
        command = command_found
      else
        if arg
          remaining_argv.unshift(arg)
        end
        break
      end
    end


    if command != app_command
      command_option_parser = new_option_parser(app_command.name) do |opts|
        opts.banner = command.description
        app_command.accepts.each_with_index { |class_or_class_and_proc,index| accept(opts,class_or_class_and_proc,index) }
        command.accepts.each_with_index { |class_or_class_and_proc,index| accept(opts,class_or_class_and_proc,index) }
        opts.on("--help", "-h", "Show help") do
          brut_provided_help_requested = true
        end
        app_command.opts.each { opts.on(*it) }
        command.opts.each { opts.on(*it) }
      end
      remaining_argv = command_option_parser.parse!(remaining_argv, into: options)
      if brut_provided_help_requested
        help_command = Brut::CLI::Commands::Help.new(command,command_option_parser)
      elsif help_command
        help_command.option_parser = command_option_parser
      end
    end

    if help_command
      command = help_command
    end

    if options[:env]
      @project_environment = options.delete(:env)
    end

    @command = command
    @argv    = remaining_argv
    @options = Brut::CLI::Options.new(options)
    if !@options.log_level?
      if @options.verbose? || @options.debug?
        @options[:'log-level'] = "debug"
      elsif @options.quiet?
        @options[:'log-level'] = "error"
      else
        @options[:'log-level'] = "info"
      end
    end
    if !@options[:'log-file']
      log_file_path = if env["XDG_STATE_HOME"]
                        Pathname(env["XDG_STATE_HOME"]) / "brut"
                      elsif env["HOME"]
                        Pathname("#{env['HOME']}/.local/state/") / "brut"
                      else
                        Pathname("/tmp/") / "brut"
                      end
      @options[:'log-file'] = log_file_path / (app_command.name + ".log")
    end
    if @options[:'log-stdout'].nil?
      @options[:'log-stdout'] = @options.verbose? || @options.debug?
    end
  rescue => ex
    @command = if env["BRUT_DEBUG"] == "true"
      Brut::CLI::Commands::RaiseError.new(ex)
    else
      Brut::CLI::Commands::OutputError.new(ex)
    end
    @argv = argv
    @options = Brut::CLI::Options.new({})
  end

private

  def new_option_parser(app_name, &block)
    OptionParser.new do |opts|
      opts.accept(Brut::Framework::ProjectEnvironment) do |value|
        Brut::Framework::ProjectEnvironment.new(value)
      end
      opts.on("--env=ENVIRONMENT", Brut::Framework::ProjectEnvironment,
              "Project environment, e.g. test, development, production. Default depends on the command")
      opts.on("--log-level=LOG_LEVEL", [ "debug", "info", "warn", "error", "fatal" ],
              "Log level, which should be debug, info, warn, error, or fatal. Defaults to error")
      opts.on("--verbose", "Set log level to debug, and show log messages on stdout")
      opts.on("--debug", "Set log level to debug, and show log messages on stdout")
      opts.on("--quiet", "Set log level to error")
      opts.on("--log-file=FILE",
              "Path to a file where log messages are written. Defaults to $XDG_CACHE_HOME/brut/logs/#{app_name}.log")
      opts.on("--[no-]log-stdout", "Log messages to stdout in addition to the log file")
      block.(opts)
    end
  end

  def accept(opts,class_or_class_and_proc,index)
    klass,conversion_proc = if class_or_class_and_proc.kind_of?(Class)
                              [ class_or_class_and_proc, ->(arg) { class_or_class_and_proc.new(arg) } ]
                            elsif class_or_class_and_proc.kind_of?(Array) && class_or_class_and_proc.size == 2
                              class_or_class_and_proc
                            else
                              raise "def accepts must return an array whose elements are either a class or a 2-element array of a class and a conversion proc.  Index #{index} had a #{class_or_class_and_proc.class}"
                            end
    opts.accept(klass,&conversion_proc)
  end
end
