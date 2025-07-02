require "optparse"
# Base class for subcommands of a {Brut::CLI::App}. You must implement {#execute} to perform whatever action this command must perform.
class Brut::CLI::Command
  include Brut::CLI::ExecutionResults
  include Brut::I18n::ForCLI
  include Brut::Framework::Errors

  # Call this to set the one-line description of this command
  #
  # @param new_description [String] When present, sets the description of this command. When omitted, returns the current description.
  # @return [String] the current description (if called with no parameters)
  def self.description(new_description=nil)
    if new_description.nil?
      return @description.to_s
    else
      @description = new_description
    end
  end


  # Call this to set a an additional detailed description of this command. Currently, this should not be formatted and will be shown all on one line. This is shown after the `description`, so this text can follow from that, without having to restate it.
  #
  # @param new_description [String] When present, sets the detailed description of this command. When omitted, returns the current detailed description.
  # @return [String] the current detailed description (if called with no parameters)
  def self.detailed_description(new_description=nil)
    if new_description.nil?
      if @detailed_description.nil?
        return @detailed_description
      end
      return @detailed_description.to_s
    else
      @detailed_description = new_description
    end
  end

  # Set a description of the command line args this command accepts. Args are any part of the command line that is not a switch or
  # flag.  The string you give will be used only for documentation. Typically, you would format it in one a few ways:
  #
  # * `args "some_arg"` indicates that exactly one arg called `some_arg` is required
  # * `args "[some_arg]"` indicates that exactly one arg called `some_arg` is optional
  # * `args "args..."` indicates that 
  # * `args "[args...]"` indicates that zero or more args called `args` are accepted
  #
  # @param [String] new_args documentation for this command's args. If omitted, returns the current value.
  # @return [String the current value (if called with no parameters)
  def self.args(new_args=nil)
    if new_args.nil?
      return @args.to_s
    else
      @args = new_args
    end
  end

  # Call this for each environment variable this *command* responds to.  These would be variables that affect only this command. For
  # app-wide environment variables, see {Brut::CLI::App.env_var}.
  #
  # @param var_name [String] Declares that this command recognizes this environment variable.
  # @param purpose [String] An explanation for how this environment variable affects the command. Used in documentation.
  def self.env_var(var_name,purpose:)
    env_vars[var_name] = purpose
  end

  # Access all configured environment variables.
  # @!visibility private
  def self.env_vars
    @env_vars ||= {
    }
  end

  # Returns the name of this command, for use on the command line.  By default, returns the "underscorized" name of this class
  # (excluding any module namespaces).  For exaple, if your command's class is `MyApp::CLI::Commands::ClearFiles::DryRun`, the command
  # name would be `"dry_run"`.  You can override this if you want something different.  It is recommended that it not include spaces
  # or other characters meaningful to the shell, but if you like quotes, cool.
  def self.command_name = RichString.new(self.name.split(/::/).last).underscorized

  # Checks if a given string matches this command name.  This exists to allow the use of underscores or dashes as delimiters.  Ruby
  # likes underscores, but the shell vibe is often dashes.
  #
  # @param [String] string the command given on the command line
  # @return [true|false] true if `string` is considered an exact match for this command's name.
  def self.name_matches?(string)
    self.command_name == string || self.command_name.to_s.gsub(/_/,"-") == string
  end

  # Provides access to an `OptionParser` you can use to declare flags and switches that should be accepted only by this command.
  # The way to use this is to call `.on` and provide a description for an option as you would to `OptionParser`.
  # The only difference is that you should not pass a block to this. When the command line is parsed, the results will be placed
  # into a {Brut::CLI::Options} instance made available to your command.
  #
  # @return [OptionParser]
  def self.opts
    self.option_parser
  end

  # Returns the configured `OptionParser` used to parse the command portion of the command line.
  # If you don't want to call {.opts}, you can create and return
  # a fully-formed `OptionParser` by overriding this method.  By default, it will create one with a conventional banner.
  #
  # @return [OptionParser]
  def self.option_parser
    @option_parser ||= OptionParser.new do |opts|
      opts.banner = "%{app} %{global_options} #{command_name} %{command_options} %{args}"
    end
  end

  # Call this if this command requires a project environment as context for what it does. When called, this will do a few things:
  #
  # * Your command (not app) will recognize `--env=ENVIRONMENT` as a global option
  # * Your command will document that it recognizes the `RACK_ENV` environment variable.
  #
  # @see Brut::CLI::App.requires_project_env
  #
  # @param default [String] name of the environment to use if none was specified. `nil` should be used to require the environment to be specified explicitly.
  def self.requires_project_env(default: "development")
    default_message = if default.nil?
                        ""
                      else
                        " (default '#{default}')"
                      end
    opts.on("--env=ENVIRONMENT","Project environment#{default_message}")
    @default_env = default
    @requires_project_env = true
    self.env_var("RACK_ENV",purpose: "default project environment when --env is omitted")
  end

  # Returns the default project env, based on the logic described in {.requires_project_env}
  def self.default_env           = @default_env
  # Returns true if this app requires a project env
  def self.requires_project_env? = @requires_project_env

  # Creates the command before executing it. Generally you would not call this directly.
  #
  # @param [Brut::CLI::Options] command_options the command options parsed from the command line.
  # @param [Brut::CLI::Options] global_options the global options parsed from the command line.
  # @param [Array] args Any unparsed arguments
  # @param [Brut::CLI::Output] out an IO used to send messages to the standard output
  # @param [Brut::CLI::Output] err an IO used to send messages to the standard error
  # @param [Brut::CLI::Executor] executor used to execute child processes instead of e.g. `system`
  def initialize(command_options:,global_options:, args:,out:,err:,executor:)
    @command_options = command_options
    @global_options  = global_options
    @args            = args
    @out             = out
    @err             = err
    @executor        = executor
    if self.class.default_env
      @command_options.set_default(:env,self.class.default_env)
    end
  end

  # Convienince method to call {Brut::CLI::Executor#system!} on the executor given in the constructor.
  # @param (see Brut::CLI::Executor#system!)
  # @return (see Brut::CLI::Executor#system!)
  def system!(*args) = @executor.system!(*args)

  # Use this inside {#execute} to createa compound command that executes other commands that are a part of your CLI app.
  # Note that each command will be given the same global and commmand options and the same arguments, so these commands must be able
  # to complete as desired in that way.
  #
  # Note that since commands are just classes, you can certianly create them however you like and call `execute` yourself.
  #
  # @param [Enumerable<Class>] command_klasses one or more classes that subclass {Brut::CLI::Command} to delegate to.
  # @return [Brut::CLI::ExecutionResults::Result] the first non successful result is returned and processing is stopped, otherwise returns the
  # result of the last class executed.
  def delegate_to_commands(*command_klasses)
    result = nil
    command_klasses.each do |command_klass|
      result = delegate_to_command(command_klass)
      if !result.ok?
        err.puts "#{command_klass.command_name} failed"
        return result
      end
    end
    result
  end

  # You must implement this to perform whatever action your command needs to perform.  In order to do this, you will have access to:
  #
  # * {#options} - the command options passed on the command line
  # * {#global_options} - the global options passed on the command line
  # * {#args} - the args passed on the command line
  # * {#out} - an IO you should use to print messages to the standard out.
  # * {#err} - on IO you should use to print messages to the standard error.
  # * {#system!} - the method you should use to spawn child processes.
  #
  # @return [Brut::CLI::ExecutionResults::Result] a description of what happened during processing. It is preferable to try to return
  # something instead of raising an exception.
  # @raise [Brurt::CLI::Error] if thrown, this will be caught and handled by {Brut::CLI::AppRunner}.
  # @raise [StandardError] if thrown, this will bubble up and show your user a very sad stack trace that will make them cry. Don't.
  def execute
    abstract_method!
  end

  # Called before any execution or bootstrapping happens but after {Brut::CLI::App#before_execute} is called.  This will have access
  # to everything {#execute} can access.
  # @raise [Brurt::CLI::Error] if thrown, this will be caught and handled by {Brut::CLI::AppRunner} and execution will be aborted.
  # @raise [StandardError] if thrown, this will bubble up and show your user a very sad stack trace that will make them cry. Don't.
  def before_execute
  end

  # Called after all setup has been executed. Brut will have been started/loaded.
  # This will *not* be called if anything caused execution to be aborted.
  #
  # @param [Brut::Framework::App] app Your Brut app.
  def after_bootstrap(app:)
  end

  # @!visibility private
  def set_env_if_needed
    if self.class.requires_project_env?
      ENV["RACK_ENV"] = options.env
    end
  end

  # Called if there is an exception during bootstrapping.  By default, it re-raises the exception, which cases the command to abort.
  # The reason you may want to overrid this is that your command line app may exist to handle a bootstrapping exception.  For example,
  # the built-in {Brut::CLI::Apps::DB} app will catch various database connection errors and then create or migrate the database.
  #
  # Yes, I realize this means we are using exceptions for control flow. It's fine.
  #
  # @param [StandardError] ex whichever exception was caught during bootstrapping
  # @return [void] ignored
  # @raise [Brurt::CLI::Error] if thrown, this will be caught and handled by {Brut::CLI::AppRunner} and execution will be aborted.
  # @raise [StandardError] if thrown, this will bubble up and show your user a very sad stack trace that will make them cry. Don't.
  def handle_bootstrap_exception(ex)
    raise ex
  end

private

  # @!visibility public
  # @return [Brut::CLI::Options] the command options parsed on the command line
  def options        = @command_options
  # @!visibility public
  # @return [Brut::CLI::Options] the global options parsed on the command line
  def global_options = @global_options
  # @!visibility public
  # @return [Array<String>] the arguments parsed from the command line
  def args           = @args
  # @!visibility public
  # @return [Brut::CLI::Output] IO to use for sending messages to the standard output
  def out            = @out
  # @!visibility public
  # @return [Brut::CLI::Output] IO to use for sending messages to the standard error
  def err            = @err

  # Exists to warn users not to use `puts`
  def puts(...)
    warn("Your CLI apps should use out and err to produce terminal output, not puts", uplevel: 1)
    Kernel.puts(...)
  end

  def delegate_to_command(command_klass)
    command = command_klass.new(command_options: options, global_options:, args:, out:, err:, executor: @executor)
    as_execution_result(command.execute)
  end


end
