class Brut::CLI::Commands::OutputError < Brut::CLI::Commands::BaseCommand
  attr_reader :exception
  def initialize(exception)
    @exception = exception
  end
  def run
    stderr.puts @exception.message
    65
  end

  def bootstrap? = false
  def default_rack_env = nil
end
