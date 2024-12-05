module Brut
  module CLI
    # Included in commands to allow convienient ways to return structured information about what happened during command 
    # execution.
    module ExecutionResults
      # Base class for all results.
      class Result
        # @return [Strting] any message provided in the results. Generally `nil` for successful results.
        attr_reader :message

        # Create a new result
        #
        # @param exit_status [Integer] exit status desired for this command. 0 is treated as success by any command that called your
        # command.  All other values have command-defined meanings.
        # @param message [String|nil] a message to explain the results, if relevant.
        def initialize(exit_status:,message:nil)
          @exit_status = exit_status
          @message = message
        end

        # @return [true|false] true if execution internal to the command should stop
        def stop?       = @exit_status != 0
        # @return [true|false] true if the execution of the command succeeded or didn't error
        def ok?         = @exit_status == 0
        # @return [Integer] the exit status
        def to_i        = @exit_status
        # @return [true|false] true if the result means that the user should be show CLI usage in addition to any messaging.
        def show_usage? = false
      end

      # @!visibility private
      class Stop < Result
        def initialize
          super(exit_status: 0)
        end
        # @return [true] true
        def stop? = true
      end

      # @!visibility private
      class ShowCLIUsage < Stop
        attr_reader :command_klass
        def initialize(command_klass:)
          super()
          @command_klass = command_klass
        end
        def show_usage? = true
      end

      # @!visibility private
      class Continue < Result
        def initialize
          super(exit_status: 0)
        end
      end

      # @!visibility private
      class Abort < Result
        def initialize(exit_status:1,message:nil)
          if exit_status == 0
            raise ArgumentError,"Do not use Abort for a zero exit status"
          end
          super(exit_status:,message:)
        end
      end
      # @!visibility private
      class CLIUsageError < Abort
        def initialize(message:)
          super(message:,exit_status:65)
        end
        def show_usage? = true
      end

      # Return this from {Brut::CLI::Command#execute} to stop execution, without signaling an error
      def stop_execution                         = Stop.new
      # Return this from {Brut::CLI::Command#execute} to indicate any other execution may continue. This is mostly useful when one
      # command calls another e.g. with {Brut::CLI::Command#delegate_to_commands}.
      def continue_execution                     = Continue.new
      # Return this from {Brut::CLI::Command#execute} to stop execution and signal an error
      #
      # @param [String] message the error message
      # @param [Integer] exit_status the exit status (should ideally not be 0)
      def abort_execution(message,exit_status:1) = Abort.new(message:,exit_status:)
      # Return this from {Brut::CLI::Command#execute} to stop execution because the user messed up the CLI invocation.
      #
      # @param [String] message the error message
      def cli_usage_error(message)               = CLIUsageError.new(message:)
      # Return this from {Brut::CLI::Command#execute} to stop execution, and show the user the CLI help, optionally for a specific
      # command.
      #
      # @param [Class] command_klass if given, this it he class whose help will be shown.
      def show_cli_usage(command_klass=nil)      = ShowCLIUsage.new(command_klass:)

      # Coerce a value to the appropriate {Brut::CLI::ExecutionResults::Result}.  Currently works as follows:
      #
      # 1. If `exit_status_or_execution_result` is nil or true, returns a successful result
      # 2. If `exit_status_or_execution_result` is an integer, returns a result with no message and that value as the exit status
      # 3. If `exit_status_or_execution_result` is false, returns {#abort_execution}.
      # 4. If `exit_status_or_execution_result` is a {Brut::CLI::ExecutionResults::Result}, returns that
      # 5. Otherwise, raises `ArgumentError`
      #
      # @param [nil|true|false|Brut::CLI::ExecutionResults::Result|Integer] exit_status_or_execution_result the value to coerce
      # @return [Brut::CLI::ExecutionResults::Result] appropriate for the parameter
      def as_execution_result(exit_status_or_execution_result)
        if exit_status_or_execution_result.kind_of?(Numeric) || exit_status_or_execution_result.nil?
          Result.new(exit_status: exit_status_or_execution_result.to_i)
        elsif exit_status_or_execution_result == true
          Result.new(exit_status: 0)
        elsif exit_status_or_execution_result == false
          Abort.new
        elsif exit_status_or_execution_result.kind_of?(Result)
          exit_status_or_execution_result
        else
          raise ArgumentError,"Your method returned a #{exit_status_or_execution_result.class} when it should return an exit status or one of the methods from ExecutionResults"
        end
      end
    end
  end
end
