require "optparse"
require_relative "../junk_drawer"

# Base class for all Brut-powered CLI Apps.  Your subclass will call or override methods to declare the UI of your CLI app, including
# the commands it provides and options it recognizes.  These mostly help to provide command-line documentation for your app, but also
# provide basic help with accessing the command line arguments and options.  Internally, this uses Ruby's `OptionParser`.
#
# The types of CLIs this framework supports are *command suites* where a single CLI app has several subcommands, similar to `git`.  As
# such, the CLI has several parts that you can configure:
#
# ```
# cli_app [global options] «subcommand» [command options] [arguments]
# ```
#
# * Global options appear between the CLI app's executable and the name of the subcommand. These affect any command. A common example is `--log-level`.  These are configured with {Brut::CLI::App.on} or {Brut::CLI::App.option_parser}.
# * Subcommand is a single string representing the command to execute.  The available commands are returned by {Brut::CLI::App.commands} although it's more conventional to declare inner classes of your app that extend {Brut::CLI::Command}.
# * Command options appear after the subcommand and apply only to that sub command.  They are declared with {Brut::CLI::Command.on} or {Brut::CLI::Command.opts}.
# * Arguments are any additional values present on the command line.  They are defined per-command and can be documented via {Brut::CLI::Command.args}.
class Brut::CLI::App
  include Brut::CLI::ExecutionResults
  include Brut::I18n::ForCLI

  # Returns a list of {Brut::CLI::Command} classes that each represent the subcommands your CLI app accepts.
  # By default, this will look for all internal classes that extend {Brut::CLI::Command} and use them as your subcommands.
  # This means that you don't need to override this method and can instead define classes inside your app subclass.
  def self.commands
    self.constants.map { |name|
      self.const_get(name)
    }.select { |constant|
      constant.kind_of?(Class) && constant.ancestors.include?(Brut::CLI::Command) && constant.instance_methods.include?(:execute)
    }
  end

  # Call this to set the one-line description of your command line app.
  #
  # @param new_description [String] When present, sets the description of this app. When omitted, returns the current description.
  def self.description(new_description=nil)
    if new_description.nil?
      return @description.to_s
    else
      @description = new_description
    end
  end

  # Call this for each environment variable your *app* responds to.  These would be variables that affect any of the subcommands. For
  # command-specific environment variables, see {Brut::CLI::Command.env_var}.
  #
  # @param var_name [String] Declares that this app recognized this environment variable.
  # @param purpose [String] An explanation for how this environment variable affects the app. Used in documentation.
  def self.env_var(var_name,purpose:)
    env_vars[var_name] = purpose
  end

  # Access all configured environment variables.
  # @!visibility private
  def self.env_vars
    @env_vars ||= {
      "BRUT_CLI_RAISE_ON_ERROR" => "if set, shows backtrace on errors"
    }
  end

  # Specify the default command to use when no subcommand is given.
  #
  # @param new_command_name [String] if present, sets the name of the command to run when none is given on the command line. When omitted, returns the currently configured name.  The default is `help`.
  def self.default_command(new_command_name=nil)
    if new_command_name.nil?
      return @default_command || "help"
    else
      @default_command = new_command_name.to_s
    end
  end

  # Provides access to an `OptionParser` you can use to declare flags and switches that should be accepted globally. The way to use
  # this is to call `.on` and provide a description for an option as you would to `OptionParser`. The only difference is that you
  # should not pass a block to this.  When the command line is parsed, the resultsl will be placed into a {Brut::CLI::Options}
  # instance made available to your command.
  #
  # @return [OptionParser]
  #
  # @example
  #
  #    class MyApp < Brut::CLI::App
  #    
  #      opts.on("--dry-run","Don't change anything, just pretend")
  #
  #    end
  def self.opts
    self.option_parser
  end

  # Returns the configured `OptionParser` used to parse the command line. If you don't want to call {.opts}, you can create and return
  # a fully-formed `OptionParser` by overriding this method.  By default, it will create one with a conventional banner.
  #
  # @return [OptionParser]
  def self.option_parser
    @option_parser ||= OptionParser.new do |opts|
      opts.banner = "%{app} %{global_options} commands [command options] [args]"
    end
  end

  # Call this if your CLI requires a project environment as context for what it does. For example, a command to analyze the database
  # needs to know if it should operate on development, test, or production.  When called, this will do a few things:
  #
  # * Your app will recognize `--env=ENVIRONMENT` as a global option
  # * Your app will recognize the `RACK_ENV` environment variable.
  #
  # When your app executes, the project environment will be determined as follows:
  #
  # 1. If `--env` was on the command line, that is the environment used
  # 2. If `RACK_ENV` is set in the environment, that is used
  # 3. Otherwise the value given to the `default:` parameter of this method is used.
  #
  # @param default [String] name of the environment to use if none was specified. `nil` should be used to require the environment to be specified explicitly.
  def self.requires_project_env(default: "development")
    default_message = if default.nil?
                        ""
                      else
                        " (default '#{default}')"
                      end
    opts.on("--env=ENVIRONMENT","Project environment#{default_message}")
    @default_env = ENV["RACK_ENV"] || default
    @requires_project_env = true
    self.env_var("RACK_ENV",purpose: "default project environment when --env is omitted")
  end

  # Returns the default project env, based on the logic described in {.requires_project_env}
  def self.default_env           = @default_env
  # Returns true if this app requires a project env
  def self.requires_project_env? = @requires_project_env

  # Call this if your app must operate before the Brut framework starts up.
  def self.configure_only!
    @configure_only = true
  end
  def self.configure_only? = !!@configure_only

  # Create the App. This is called by {Brut::CLI::AppRunner}.
  #
  # @param [Brut::CLI::Options] global_options global options specified on the command line
  # @param [Brut::CLI::Output] out IO to use to send output to the standard output
  # @param [Brut::CLI::Output] err IO to use to send output to the standard error
  # @param [Brut::CLI::Executor] executor Class to use to execute child processes instead of e.g. `system`.
  def initialize(global_options:,out:,err:,executor:)
    @global_options = global_options
    @out            = out
    @err            = err
    @executor       = executor
    if self.class.default_env
      @global_options.set_default(:env,self.class.default_env)
    end
  end

  # @!visibility private
  def set_env_if_needed
    if self.class.requires_project_env?
      ENV["RACK_ENV"] = options.env
    end
  end

  # @!visibility private
  def load_env(project_root:)
    if !ENV["RACK_ENV"]
      ENV["RACK_ENV"] = "development"
    end
    env = ENV["RACK_ENV"]
    if env != "production"
      require "dotenv"
      Dotenv.load(project_root / ".env.#{env}",
                  project_root / ".env.#{env}.local")

    end
  end

  # Called before anything else happens. You can override this to perform any setup or other checking before Brut is started up.
  def before_execute
  end

  # Called after all setup has been executed. Brut will have been started/loaded.  This will *not* be called if anything
  # caused execution to be aborted.
  def after_bootstrap
  end

  def configure!
  end

  # Executes the command.  Called by {Brut::CLI::AppRunner}.
  #
  # @param [Brut::CLI::Command] command the command to run, based on what was on the command line
  # @param [Pathname] project_root root of the Brut app's project files.
  def execute!(command,project_root:)
    before_execute
    set_env_if_needed
    command.set_env_if_needed
    load_env(project_root:)
    command.before_execute
    bootstrap_result = begin
                         require "#{project_root}/app/bootstrap"
                         bootstrap = Bootstrap.new
                         if self.class.configure_only?
                           bootstrap.configure_only!
                         else
                           bootstrap.bootstrap!
                         end
                         continue_execution
                       rescue => ex
                         as_execution_result(command.handle_bootstrap_exception(ex))
                       end
    if bootstrap_result.stop?
      return bootstrap_result
    end
    after_bootstrap
    as_execution_result(command.execute)
  rescue Brut::CLI::Error => ex
    abort_execution(ex.message)
  end

private

  def options = @global_options
  def out = @out
  def err = @err
  def puts(...)
    warn("Your CLI apps should use out.puts or err.puts or produce terminal output, not plain puts", uplevel: 1)
    Kernel.puts(...)
  end

end
