require "brut/junk_drawer"
class Brut::CLI::Commands::BaseCommand

  attr_accessor :parent_command

  # The name of the command that the developer should use on the command line. By default, this is
  # the underscorized version of the class' simple name.
  # @return [String] String the developer should use on the command line. If it has spaces or
  #         characters special to the shell, you will have a great sadness and possibly other mayhem.
  def name = RichString.new(self.class.name.split(/::/).last).underscorized

  # Execute the command in the given context.  This is the method to call to execute a command programmatically, however you
  # should not override this method. Instead, override `.run` to provide your command's logic.
  #
  # @param [Brut::CLI::ExecutionContext] execution_context the context in which the command will run, providing access
  # to standard streams, the parsed options, and unparsed arguments.
  def execute(execution_context)
    @execution_context = execution_context
    self.run
  end

  def delegate_to_command(command,execution_context=:use_ivar)
    execution_context = if execution_context == :use_ivar
                          @execution_context
                        else
                          execution_context
                        end
    if execution_context.nil?
      raise ArgumentError, "No execution context provided and none set on this command"
    end
    execute_result = Brut::CLI::ExecuteResult.new do
      command.execute(execution_context)
    end
    if execute_result.failed?
      return execute_result.exit_status do |error_message|
        puts theme.error.render(error_message)
      end
    else
      0
    end
  end

  # True if the command requires Brut to fully bootstrap and start itself up.  Bootstrapping isn't running a web server but it will
  # do everything else, including connecting too all databases.  Your command should return true for this if it needs to access a database
  # or make API calls outside `Brut::CLI`. If this returns false, Brut's configuration options will still be available.
  #
  # By default, this returns false
  #
  # @return [true|false] True if Brut should be fully bootstrap and connect to all database servers (e.g.). False if Brut should only
  #                      set up its configuration options.
  def bootstrap? = false

  # The default `RACK_ENV` to use for this command.  This value is used when no `RACK_ENV` is present in the UNIX environment
  # and when `--env` has not been used on the command line. Do note that setting this in an app or parent command does
  # not translate to the subcommands.
  #
  # @return [String|nil] If nil, Brut configuration will not be loaded and the command will run more or less as if it were a plain
  #         Ruby script.  If a `String`, this value will be set as the `RACK_ENV` if it's not been otherwise specified.
  def default_rack_env = nil

  # @return [String] description of this command for use in help output
  def description = ""

  def detailed_description = nil

  # @return [String] description of the arguments this command accepts. Used for documentation only.
  def args_description = nil

  # @return [Array<Array<String>>] Array of arrays documenting which environment variables affect this command's behavior.
  #         The array should have two elements: the env var name as a string, and a string documenting its purpose. This is
  #         used for documentation only.
  def env_vars = []

  # Used to specify the command line options for the command.
  # @return [Array<Array<Object>>] an array of arrays representing this command's reecognized command line options.  Each member
  #         of the array is treated as arguments to `OptionParser#on`.  Please consult the Rubydoc for that method to know what
  #         you can use here.  It is quite flexible, including type conversions, documentation, and multiple forms of options.
  def opts = []

  # Specify type conversions for options.  This is a loose wrapper around `OptionParser#accept` with a convienience feature
  # to allow simpler conversions without a proc.
  #
  # @example
  #   class Type
  #     def initialize(value)
  #       value = value.to_s
  #       if ["new", "old", "promoted" ].include?(value)
  #         @value = value
  #       else
  #         raise ArgumentError, "'#{value}' is not a valid Type"
  #       end
  #     end
  #   end
  #   def opts = [
  #     [ "--type=TYPE", "The type of thing", Type ]
  #   ]
  #   def accepts = [
  #     Type,
  #   ]
  #   # or
  #   def accepts = [
  #     [ Type, ->(val) { Type.new(val) },
  #   ]
  #
  # @return [Array<Array>|Array<Class>] Must be an array.  Any element that is a class will be used to convert any options
  #         of that type when the type is used in `opts`.  If the element is a class, it is assumed that values can be converted
  #         via `.new`.  If the class does not support `.new` as a conversion method, the element should be a two-element array
  #         where index 0 is the class and index 1 is a proc to convert the command line argument to the class's type.
  def accepts = []

  # Returns a list of commands that represent the subcommands available to this command. By default, this
  # will return all commands that are inner classes of this command.
  #
  # @return [Array<Brut::CLI::Commands::BaseCommand>]
  def commands
    self.class.constants.map { |name|
      self.class.const_get(name)
    }.select { |constant|
      constant.kind_of?(Class) && constant.ancestors.include?(Brut::CLI::Commands::BaseCommand)
    }.map(&:new)
  end

private

  # Provides access the `Brut::CLI::Commands::ExecutionContext` used the last time `#execute` was called.
  # This should only be accessed in tests and sparingly.
  def execution_context
    @execution_context ||= Brut::CLI::Commands::ExecutionContext.new
  end

  # Access the command line arguments leftover after all options have been parsed, when `.execute` was called
  #
  # @return [Array<String>] leftover command line arguments
  # @!visibility public
  def argv = self.execution_context.argv

  # Convienience methods to defer to `Brut::CLI::Commands::ExecutionContext`'s `Brut::CLI::Executor#system!`.
  # @!visibility public
  def system!(*args,&block)
    output = ""
    block ||= ->(output_chunk) {
      output << output_chunk
    }
    self.execution_context.executor.system!(*args,&block).tap {
      if output.length > 0
        info output
      end
    }
  end

  # Convienience methods to defer to `Brut::CLI::Commands::ExecutionContext#stdout`'s  `puts`.
  # @!visibility public
  def puts(*args)
    if !options.quiet?
      self.execution_context.stdout.puts(*args)
    end
  end
  def print(*args)
    if !options.quiet?
      self.execution_context.stdout.print(*args)
    end
  end

  def debug(message) = self.execution_context.logger.debug(message)
  def info(message)  = self.execution_context.logger.info(message)
  def warn(message)  = self.execution_context.logger.warn(message)
  def error(message) = self.execution_context.logger.error(message)
  def fatal(message) = self.execution_context.logger.fatal(message)

  def theme
    @theme = Brut::CLI::TerminalTheme.new(terminal:)
  end

  def terminal
    @terminal ||= Brut::CLI::Terminal.new
  end

  # Convienience methods to defer to `Brut::CLI::Commands::ExecutionContext#stdin`. You should use this over `STDIN` of `$stdin`.
  # @!visibility public
  def stdin   = self.execution_context.stdin
  # Convienience methods to defer to `Brut::CLI::Commands::ExecutionContext#options`.
  # @!visibility public
  def options = self.execution_context.options
  # Convienience methods to defer to `Brut::CLI::Commands::ExecutionContext#env`. You should use this over `ENV`.
  # @!visibility public
  def env     = self.execution_context.env


  # Runs whatever logic this command exists to execute.  This is the method you must implement, however `#execute` is the public
  # API and what you should call if you want to programmatically execute a command.
  #
  # The default implementation will generate an error, which is suitable for an app or namespace command that require a subcommand.
  #
  # @return [Integer|Object|StandardError] When an integer is returned, that is considered the exit status of the CLI
  #         invocation that ultimately called this command. If an `Object` (including `nil` and non-`Integer` numbers) is returned,
  #         the command is assumed to have succeeded and the return value is ignored.  If an exception is returned, it's treated
  #         the same as if it were raised (don't return an exception).
  # @raise [Brut::CLI::Error|StandardError] If a `Brut::CLI::Error`, the command
  #         is considered failed and the exception's message is printed to stderr and the exit status is nonzero. If another
  #         type of exception, it is bubbled up and shown to the user. Generally do not return any sort of  exception - allow it to raise.
  # @!visibility public
  def run
    if argv[0]
      puts theme.error.render("No such command '#{argv[0]}'")
      return 1
    end

    puts theme.error.render("Command is required")
    1
  end
end
