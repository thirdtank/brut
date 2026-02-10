module Brut
  # Brut provides a basic CLI framework for building CLIs that have access to your Brut app's innerworkings.
  # This is an alternative to Rake tasks which suffer from poor usability and testability.
  #
  # To create a CLI, you will subclass {Brut::CLI::App}. That class will define your UI as well as any subcommands
  # that your CLI will respond to. See {Brut::CLI::app}.
  module CLI

    autoload(:Commands, "brut/cli/commands")
    autoload(:Error, "brut/cli/error")
    autoload(:ExecuteResult, "brut/cli/execute_result")
    autoload(:Executor, "brut/cli/executor")
    autoload(:InvalidOption, "brut/cli/error")
    autoload(:Options, "brut/cli/options")
    autoload(:Output, "brut/cli/output")
    autoload(:ParsedCommandLine, "brut/cli/parsed_command_line")
    autoload(:Runner, "brut/cli/runner")
    autoload(:SystemExecError, "brut/cli/error")
    autoload(:Terminal, "brut/cli/terminal")
    autoload(:TerminalTheme, "brut/cli/terminal_theme")
    autoload(:Logger, "brut/cli/logger")

    # Holds Brut-provided CLI apps that are set up in your project.
    module Apps
      autoload(:BuildAssets,"brut/cli/apps/build_assets")
      autoload(:DB,"brut/cli/apps/db")
      autoload(:Deploy,"brut/cli/apps/deploy")
      autoload(:New,"brut/cli/apps/new")
      autoload(:Scaffold,"brut/cli/apps/scaffold")
      autoload(:Test,"brut/cli/apps/test")
    end
  end
end
require_relative "i18n"
