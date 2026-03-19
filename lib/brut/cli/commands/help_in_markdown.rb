class Brut::CLI::Commands::HelpInMarkdown < Brut::CLI::Commands::BaseCommand
  def description = "Get help for the app or a command, in Markdown"
  attr_accessor :option_parser

  def initialize(command,option_parser)
    @command = command
    @option_parser = option_parser
  end

  def commands = []

  def run
    if env["BRUT_HELP_IN_MARKDOWN_COMMANDS_ONLY"]
      @command.commands.sort_by(&:name).each do |command|
        puts command.name
      end
      return 0
    end
    cli = [@command.name ]
    cmd = @command
    while cmd.parent_command
      cmd = cmd.parent_command
      cli.unshift cmd.name
    end
    invocation = cli.join(" ")
    puts "# `#{invocation}`"
    puts
    puts @command.description
    puts

    usage = invocation

    options = @option_parser.top.list
    if options.size > 0
      usage << theme.weak.render(" [options]")
    end
    if @command.commands.any?
      usage << theme.code.render(" command")
    end
    if @command.args_description
      usage << " #{@command.args_description}"
    end
    puts
    puts "## USAGE"
    puts
    puts "    " + usage
    puts
    if @command.detailed_description
      puts
      puts "## DESCRIPTION"
      puts
      puts @command.detailed_description.gsub(/ +/," ").strip
      puts
    end
    if options.size > 0
      puts
      puts "## OPTIONS"
      puts

      options.each do |option|
        switches = option.long.map { |switch|
          if option.arg
            if option.arg[0] == "="
              "#{switch.strip}#{theme.weak.render(option.arg.strip)}"
            else
              "#{switch.strip}=#{theme.weak.render(option.arg.strip)}"
            end
          else
            switch
          end
        } + option.short.map { |switch|
          if option.arg
            "#{switch} #{theme.weak.render(option.arg)}"
          else
            switch
          end
        }
        puts "* `#{switches.join(", ")}` - #{option.desc.join(" ")}"
      end
    end
    if @command.env_vars.any?
      puts
      puts "## ENVIRONMENT VARIABLES"
      puts
      @command.env_vars.sort_by(&:first).each do |env_var|
        puts "* `#{env_var[0]}` -  #{env_var[1]}"
      end
    end
    if @command.commands.any?
      commands_subpath = env["BRUT_HELP_IN_MARKDOWN_COMMAND_PATH"] || "commands"
      puts
      puts "## COMMANDS"
      puts
      @command.commands.sort_by(&:name).each do |command|
        puts "### [`#{command.name}`](./#{commands_subpath}/#{command.name})"
        puts
        puts "#{command.description}"
        if command.detailed_description
          puts
          puts command.detailed_description.gsub(/ +/," ").strip
        end
      end
    end
    0
  end

  def bootstrap? = false
  def default_rack_env = nil
end
