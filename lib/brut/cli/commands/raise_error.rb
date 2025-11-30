class Brut::CLI::Commands::RaiseError < Brut::CLI::Commands::BaseCommand
  attr_reader :exception
  def initialize(exception)
    @exception = exception
  end
  def run
    raise @exception
  end
  def bootstrap? = false
  def default_rack_env = nil
end
