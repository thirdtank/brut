# Wraps the result of calling `Brut::CLI::Commands::BaseCommand#execute` and 
# interpreting it as an exit code
class Brut::CLI::ExecuteResult
  attr_reader :actual_result
  def initialize(&block)
    @actual_result = begin
                       block.()
                     rescue Brut::CLI::Error => ex
                       ex
                     rescue => ex2
                       raise

                     end
  end

  def success? =  self.exit_status == 0
  def failed?  = !self.success?

  # Get the exit status for the given result.  This will call
  # the block given with an error message if there is one.
  #
  # @yield [error_message] If a block is passed, it's called when a {Brut::CLI::Error} was the return
  #        value of the command, so that you can access the message of the error.
  # @yieldparam error_message [String] the error message from the {Brut::CLI::Error}.
  #
  # @return [Integer] value betweeen 0 and 255 representing the exit status to use based on the 
  #         value the command returned.
  def exit_status(&when_error_message)
    when_error_message ||= ->(*){}
    case @actual_result
    in Integer
      @actual_result
    in Brut::CLI::SystemExecError
      when_error_message.(@actual_result.message)
      @actual_result.exit_status
    in Brut::CLI::Error
      when_error_message.(@actual_result.message)
      1
    else
      0
    end
  end
end
