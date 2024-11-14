module Brut
  module CLI

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
    module Apps
      autoload(:DB,"brut/cli/apps/db")
      autoload(:DB,"brut/cli/apps/test")
      autoload(:DB,"brut/cli/apps/build_assets")
      autoload(:DB,"brut/cli/apps/scaffold")
    end
  end
end
require_relative "i18n"
