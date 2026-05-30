require "stringio"
require "brut/cli"
require_relative "matchers/have_executed"

# Convienience methods included in tests for CLI commands
module Brut::SpecSupport::CLICommandSupport
  # A subclass of {Brut::CLI::Executor} that remembers the commands it was asked to execute, instead of
  # actually executing them.  This allows inspection later to see if expected commands had been run.
  #
  # This is used by the `have_executed` matcher.  It also is useful when yielding a block to
  # `test_execution_context` so that you can configure command line executions to raise errors or
  # provide specific output.
  class CapturingExecutor < Brut::CLI::Executor
    attr_reader :commands_executed
    def initialize(...)
      super
      @on_commands = {}
    end
    def system!(*args)
      @commands_executed ||= []
      command = if args.length == 1
                  args[0]
                else
                  args
                end
      @commands_executed << command
      on_command = @on_commands.select { |it,_|
        it == command || it.match?(command)
      }.map { |_,it| it }.first
      if on_command
        if on_command[:raise_error]
          raise Brut::CLI::SystemExecError.new(command,1)
        elsif on_command[:output]
          output = on_command[:output]
          if block_given?
            yield(output)
          else
            @out.puts output
          end
        end
      end
      nil
    end

    # Configure the behavior of a specific command. This must be called before any 
    # command line commands are invoked.
    #
    # @param [String] command the *exact* command line invocation you want to configure.
    # @param [false|true] raise_error if true, an execption is raised when this command is executed.
    # @param [String] output if not-nil, this output is produced by the command.
    def on_command(command, raise_error: false, output: nil)
      if raise_error
        @on_commands[command] = { raise_error: }
      elsif output
        @on_commands[command] = { output: }
      end
    end
  end
  # Create an ExecutionContext suitable for any command, but which allows
  # manipulating the data as needed for your test, or to access the various IO streams
  # used by the command.
  # @param [Array<String>] argv the arguments remaining on the command line after parsing
  # @param [Hash<Symbol|String,String>] options hash of options. The preceding dashes **must be omitted**.  If strings are passed as keys, they are converted to symbols.
  # @param [Hash<String,String>] env The UNIX environment to use.
  # @param [StringIO] stdin IO to use as the standard input.
  # @param [StringIO] stdout IO to use as the standard output. Note that you usually do not want to specify this, as the default is to create a `StringIO` which you can access directly from the returned execution context.
  # @param [StringIO] stderr IO to use as the standard error. Note that you usually do not want to specify this, as the default is to create a `StringIO` which you can access directly from the returned execution context.
  # @param [Brut::CLI::Executor] executor executor to use to execute sub commands. Note that you likely
  # don't want to pass in a value for this. The default is an implementation that captures all the
  # commands that were executed for your later inspection via the `have_executed` matcher.
  # @yield [executor] If a block is passed, the executor is yielded to allow for configuration of its behavior.
  # @yieldparam executor [Brut::CLI::Executor|Brut::SpecSupport::CLICommandSupport::CapturingExecutor] the executor.  If you used the default and did not provide your own, you'll get a `CapturingExecutor` that you can use to configure responses to command line invocations.
  def test_execution_context(
    argv: [],
    options: {},
    env: {},
    stdin: StringIO.new,
    stdout: StringIO.new,
    stderr: StringIO.new,
    executor: :default,
    logger: :default,
    &block
  )
    logger = if logger == :default
               Brut::CLI::Logger.new(app_name: $0, stdout:, stderr:)
             else
               logger
             end
    executor = if executor == :default 
                 CapturingExecutor.new(out: stdout, err: stderr, logger:)
               else
                 executor
               end

    if block
      block.(executor)
    end
    options = options.map { |key,value|
      [ key.to_sym, value ]
    }.to_h
    Brut::CLI::Commands::ExecutionContext.new(
      argv:,
      options: Brut::CLI::Options.new({ "log-level": "error" }.merge(options)),
      env: { "NO_COLOR" => "1" }.merge(env),
      stdin:,
      stdout:,
      stderr:,
      executor:
    )
  end
end
