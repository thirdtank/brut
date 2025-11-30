class Brut::CLI::Commands::Help < Brut::CLI::Commands::BaseCommand
  def description = "Get help for the app or a command"
  attr_accessor :option_parser

  def initialize(command,option_parser)
    @command = command
    @option_parser = option_parser
  end

  def commands = []

  def run
    stdout.puts_no_prefix @option_parser.to_s
    if @command.commands.any?
      stdout.puts_no_prefix
      stdout.puts_no_prefix "COMMANDS"
      stdout.puts_no_prefix
      @command.commands.each do |command|
        stdout.puts_no_prefix "  #{command.name} - #{command.description}"
      end
    end
    0
  end
  def bootstrap? = false
  def default_rack_env = nil
end
