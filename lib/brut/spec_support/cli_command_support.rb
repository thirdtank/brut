require "stringio"
require "brut/cli"
require_relative "matchers/have_executed"

# Convienience methods included in tests for CLI commands
module Brut::SpecSupport::CLICommandSupport
  # A subclass of {Brut::CLI::Executor} that remembers the commands it was asked to execute, instead of
  # actually executing them.  This allows inspection later to see if expected commands had been run.
  #
  # This is used by the `have_executed` matcher.
  class CapturingExecutor < Brut::CLI::Executor
    attr_reader :commands_executed
    def system!(*args)
      @commands_executed ||= []
      if args.length == 1
        @commands_executed << args[0]
      else
        @commands_executed << args
      end
      nil
    end
  end
  # Create an ExecutionContext suitable for any command, but which allows
  # manipulating the data as needed for your test, or to access the various IO streams
  # used by the command.
  def test_execution_context(
    argv: [],
    options: {},
    env: {},
    stdin: StringIO.new,
    stdout: StringIO.new,
    stderr: StringIO.new,
    executor: :default,
    logger: :default
  )
    logger = if logger == :default
               Brut::CLI::Logger.new(app_name: $0, stdout:, stderr:)
             else
               logger
             end
    Brut::CLI::Commands::ExecutionContext.new(
      argv:,
      options: Brut::CLI::Options.new({ "log-level": "error" }.merge(options)),
      env: { "NO_COLOR" => "1" }.merge(env),
      stdin:,
      stdout:,
      stderr:,
      executor: executor == :default ? CapturingExecutor.new(out: stdout, err: stderr, logger:) : executor,
    )
  end
end
