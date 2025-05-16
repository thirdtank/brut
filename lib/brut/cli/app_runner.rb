module Brut
  module CLI
    # Manages the execution of a CLI app that extends {Brut::CLI::App}. Generally you won't use this class directly, but will call
    # {Brut::CLI.app}.
    class AppRunner
      include Brut::CLI::ExecutionResults

      # Create the app runner with a class and project root
      #
      # @param [Class] app_klass The class of your app that extends {Brut::CLI::App}
      # @param [Pathname] project_root path to the root of the project
      def initialize(app_klass:,project_root:)
        @app_klass    = app_klass
        @project_root = project_root
      end

      # Runs the app, based on the CLI arguments and UNIX environment provided at the time of execution.
      def run!
        app_klass = @app_klass
        out       = Brut::CLI::Output.new(io: $stdout,prefix: "[ #{$0} ] ")
        err       = Brut::CLI::Output.new(io: $stderr,prefix: "[ #{$0} ] ")
        executor  = Brut::CLI::Executor.new(out:,err:)

        result,remaining_argv,global_options,global_option_parser = parse_global(app_klass:,out:)

        if result.stop?
          return result.to_i
        end

        result,command_klass = locate_command(remaining_argv:,app_klass:,err:,out:)

        if result.stop?
          if !result.ok?
            err.puts_no_prefix "error: #{result.message}"
            err.puts_no_prefix
            if result.show_usage?
              show_global_help(app_klass:,out:)
              err.puts_no_prefix "error: #{result.message}"
            end
          elsif result.show_usage?
            command_klass = result.command_klass
            if command_klass.nil?
              show_global_help(app_klass:,out:)
            else
              command_option_parser = command_klass.option_parser
              show_command_help(global_option_parser:,command_option_parser:,command_klass:,out:,app_klass:)
            end
          end
          return result.to_i
        end

        command_options = {}

        command_option_parser = command_klass.option_parser

        command_option_parser.on("-h", "--help", "Get help on this command") do
          show_command_help(global_option_parser:,command_option_parser:,command_klass:,out:,app_klass:)
          return 0
        end

        command_argv = remaining_argv[1..-1] || []
        begin
          args = command_option_parser.parse!(command_argv,into:command_options)
        rescue OptionParser::ParseError => ex
          raise Brut::CLI::InvalidOption.new(ex, context: command_klass)
        end

        cli_app = app_klass.new(global_options:, out:, err:, executor:)
        cmd = command_klass.new(command_options:Brut::CLI::Options.new(command_options),global_options:, args:, out:, err:, executor:)

        result = cli_app.execute!(cmd, project_root:@project_root)

        if result.message
          if !result.ok?
            err.puts "error: #{result.message}"
            if result.show_usage?
              err.puts
              show_command_help(global_option_parser:,command_option_parser:,command_klass:,out:)
            end
          else
            out.puts result.message
          end
        end
        result.to_i
      rescue OptionParser::InvalidArgument => ex
        flag = ex.args.map { |_| _.gsub(/=.*$/,"") }.join(", ")
        err.puts "error: #{ex.reason} from #{flag}: value given is not one of the allowed values"
        65
      rescue OptionParser::ParseError => ex
        err.puts "error: #{ex.message}"
        65
      rescue => ex
        if ENV["BRUT_CLI_RAISE_ON_ERROR"] == "true"
          raise
        else
          err.puts "error: #{ex.message}"
          70
        end
      end

    private

      def locate_command(remaining_argv:,app_klass:,err:,out:)

        command_name = remaining_argv[0] || app_klass.default_command

        if !command_name
          return cli_usage_error("#{$0} requires a command")
        end

        if command_name == "help"
          command_needing_help = remaining_argv[1]
          if command_needing_help
            command_klass = app_klass.commands.detect { |c| c.name_matches?(remaining_argv[1]) }
            if command_klass
              return show_cli_usage(command_klass)
            end
            return cli_usage_error("No such command '#{command_needing_help}'")
          end
          return show_cli_usage
        end

        command_klass = app_klass.commands.detect { |c| c.name_matches?(command_name) }

        if !command_klass
          return cli_usage_error("#{command_name} is not a known command")
        end
        [ continue_execution, command_klass ]
      end


      def show_global_help(app_klass:,out:)
        option_parser = app_klass.option_parser
        option_parser.banner =  option_parser.banner % {
          app: $0,
          global_options: option_parser.top.list.length == 0 ? "" : "[global options]",
        }
        out.puts_no_prefix option_parser.banner
        out.puts_no_prefix
        out.puts_no_prefix "   #{app_klass.description}"
        out.puts_no_prefix
        out.puts_no_prefix "GLOBAL OPTIONS"
        out.puts_no_prefix
        option_parser.summarize do |line|
          out.puts_no_prefix line
        end
        out.puts_no_prefix
        out.puts_no_prefix "ENVIRONMENT VARIABLES"
        out.puts_no_prefix
        max_length = app_klass.env_vars.keys.map(&:length).max
        printf_string = "    %-#{max_length}s - %s\n"
        app_klass.env_vars.keys.sort.each do |var_name|
          out.printf_no_prefix(printf_string,var_name,app_klass.env_vars[var_name])
        end
        out.puts_no_prefix
        if app_klass.commands.any?
          out.puts_no_prefix
          out.puts_no_prefix "COMMANDS"
          out.puts_no_prefix
          max_length = [ 4, app_klass.commands.map { |_| _.command_name.to_s.length }.max ].max
          printf_string = "    %-#{max_length}s - %s%s\n"
          out.printf_no_prefix printf_string, "help", "Get help on a command",""
          app_klass.commands.sort_by(&:command_name).each  do |command|
            default_message = if command.name_matches?(app_klass.default_command)
                                " (default)"
                              else
                                ""
                              end

            description = if command.description && command.description.kind_of?(Proc)
                            command.description.()
                          else
                            command.description
                          end
            out.printf_no_prefix printf_string, command.command_name, command.description, default_message
          end
        end
        out.puts_no_prefix
      end

      def show_command_help(global_option_parser:,command_option_parser:,command_klass:,out:,app_klass:)
        banner = command_option_parser.banner % {
          app: $0,
          global_options: global_option_parser.top.list.length == 0 ? "" : "[global options]",
          command_options: command_option_parser.top.list.length == 0 ? "" : "[command options]",
          args: command_klass.args,
        }
        command_option_parser.banner = "Usage: #{banner}"
        out.puts_no_prefix command_option_parser.banner
        out.puts_no_prefix
        out.puts_no_prefix "    " + command_klass.description
        out.puts_no_prefix
        if command_klass.detailed_description
          out.puts_no_prefix "    " + command_klass.detailed_description.strip
          out.puts_no_prefix
        end
        out.puts_no_prefix "GLOBAL OPTIONS"
        out.puts_no_prefix
        global_option_parser.summarize do |line|
          out.puts_no_prefix line
        end
        out.puts_no_prefix
        out.puts_no_prefix "ENVIRONMENT VARIABLES"
        out.puts_no_prefix
        all_vars = app_klass.env_vars.merge(command_klass.env_vars)
        max_length = all_vars.keys.map(&:length).max
        printf_string = "    %-#{max_length}s - %s\n"
        all_vars.keys.sort.each do |var_name|
          out.printf_no_prefix(printf_string,var_name,all_vars[var_name])
        end
        out.puts_no_prefix
        if command_option_parser.top.list.length > 0
          out.puts_no_prefix
          out.puts_no_prefix "COMMAND OPTIONS"
          if command_option_parser.summarize.any?
            out.puts_no_prefix
          end
          command_option_parser.summarize do |line|
            out.puts_no_prefix line
          end
        end
      end

      def parse_global(app_klass:,out:)
        option_parser = app_klass.option_parser

        option_parser.on("-h", "--help", "Get help") do
          show_global_help(app_klass:,out:)
          return stop_execution
        end
        log_levels = [ "debug", "info", "warn", "error", "fatal" ]
        if ENV["LOG_LEVEL"].to_s == ""
          ENV["LOG_LEVEL"] = log_levels[-1]
        end
        option_parser.on("--log-level=LEVEL","Set log level. Allowed values: #{log_levels.join(', ')}. Default '#{ENV["LOG_LEVEL"]}'",log_levels) do |value|
          ENV["LOG_LEVEL"] = value
        end
        option_parser.on("--verbose","Set log level to '#{log_levels[0]}', which will produce maximum output") do
          ENV["LOG_LEVEL"] = log_levels[0]
        end
        app_klass.env_var("LOG_LEVEL",purpose: "log level if --log-level or --verbose is omitted")

        hash = {}
        remaining_argv = option_parser.order!(into:hash)
        global_options = Brut::CLI::Options.new(hash)
        [ continue_execution, remaining_argv, global_options, option_parser ]
      rescue OptionParser::ParseError => ex
        raise Brut::CLI::InvalidOption.new(ex, context: :global)
      end
    end
  end
end
