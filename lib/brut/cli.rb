module Brut
  # Brut provides a basic CLI framework for building CLIs that have access to your Brut app's innerworkings.
  # This is an alternative to Rake tasks which suffer from poor usability and testability.
  #
  # To create a CLI, you will subclass {Brut::CLI::App}. That class will define your UI as well as any subcommands
  # that your CLI will respond to. See {Brut::CLI::app}.
  module CLI

    # Execute your CLI based on its command line invocation.  You would call this method inside the executable file placed in `bin/`
    # in your project.  For example, if you have `YourApp::CLI::CleanOldFiles` and you wish to execute it via `bin/clean-files`, you'd
    # create `bin/clean-files` like so:
    #
    # ```
    # #!/usr/bin/env ruby
    #
    # require "bundler"
    # Bundler.require
    # require "pathname"
    # require "brut/cli/apps/db"
    # 
    # exit Brut::CLI.app(YourApp::CLI::CleanOldFiles,
    #                    project_root: Pathname($0).dirname / "..")
    # ```
    #
    # @param app_klass [Class] your CLI app's class.
    # @param project_root [Pathname] the path to the root of your project. This is needed before the Brut framework is initialized so
    # it must be specified explicitly.
    def self.app(app_klass, project_root:)
      Brut::CLI::AppRunner.new(app_klass:,project_root:).run!
    end
    autoload(:App, "brut/cli/app")
    autoload(:Command, "brut/cli/command")
    autoload(:Error, "brut/cli/error")
    autoload(:SystemExecError, "brut/cli/error")
    autoload(:ExecutionResults, "brut/cli/execution_results")
    autoload(:Options, "brut/cli/options")
    autoload(:Output, "brut/cli/output")
    autoload(:Executor, "brut/cli/executor")
    autoload(:AppRunner, "brut/cli/app_runner")
    # Holds Brut-provided CLI apps that are set up in your project.
    module Apps
      autoload(:DB,"brut/cli/apps/db")
      autoload(:DB,"brut/cli/apps/test")
      autoload(:DB,"brut/cli/apps/build_assets")
      autoload(:DB,"brut/cli/apps/scaffold")
    end
  end
end
require_relative "i18n"
