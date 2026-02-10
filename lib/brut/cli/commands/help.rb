class Brut::CLI::Commands::Help < Brut::CLI::Commands::BaseCommand
  def description = "Get help for the app or a command"
  attr_accessor :option_parser

  def initialize(command,option_parser)
    @command = command
    @option_parser = option_parser
  end

  def commands = []

  class DescriptionList
    def initialize(term_align: :right, padding_bottom: 1)
      @term_align = term_align
      @padding_bottom = padding_bottom
      @rows       = []
    end
    def <<(row)
      @rows << row
    end

    def lipgloss_table(theme:, terminal:)
      indent = "  "
      term_width = @rows.map { |r| r[0].length }.max
      description_width = terminal.cols - indent.length - term_width - 2
      formatted_rows = @rows.map { |row|
        [
          row[0],
          theme.wrap(row[1], indent: 0, max_width: description_width).strip,
        ]
      }
      Lipgloss::Table.new.
        border(:hidden).
        rows(formatted_rows).
        style_func(rows: formatted_rows.length, columns: 2) { |row,column|
        if column == 0
          Lipgloss::Style.new.inherit(theme.subheader).padding_bottom(@padding_bottom).align(@term_align)
        else
          Lipgloss::Style.new.padding_bottom(@padding_bottom)
        end
      }
    end
  end
  

  def run
    cli = [@command.name ]
    cmd = @command
    while cmd.parent_command
      cmd = cmd.parent_command
      cli.unshift cmd.name
    end
    invocation = cli.join(" ")
    puts theme.code.render(invocation) + " - " + theme.title.render(theme.wrap(@command.description, indent: invocation.length + 3, max_width: 65).strip)
    puts
    usage = theme.code.render(invocation)
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
    puts theme.header.render("USAGE")
    puts
    puts "  " + usage
    puts
    if @command.detailed_description
      puts theme.header.render("DESCRIPTION")
      puts
      puts theme.wrap(@command.detailed_description.strip, indent: 2, max_width: 65)
      puts
    end
    if options.size > 0
      puts theme.header.render("OPTIONS")
      list = DescriptionList.new
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
        list << [
          switches.join("\n"),
          option.desc.join(" "),
        ]
      end
      puts list.lipgloss_table(theme:, terminal:).render
    end
    if @command.env_vars.any?
      puts theme.header.render("ENVIRONMENT VARIABLES")
      list = DescriptionList.new
      @command.env_vars.sort_by(&:first).each do |env_var|
        list << [
          env_var[0],
          env_var[1],
        ]
      end
      puts list.lipgloss_table(theme:, terminal:).render
    end
    if @command.commands.any?
      puts theme.header.render("COMMANDS")
      list = DescriptionList.new(term_align: :left, padding_bottom: 0)
      @command.commands.sort_by(&:name).each do |command|
        list << [
          command.name,
          command.description,
        ]
      end
      puts list.lipgloss_table(theme:, terminal:).render
    end
    0
  end

  def bootstrap? = false
  def default_rack_env = nil
end
