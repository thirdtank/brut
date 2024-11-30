require "optparse"
require_relative "../junk_drawer"
class Brut::CLI::App
  include Brut::CLI::ExecutionResults
  include Brut::I18n::ForCLI

  def self.commands
    self.constants.map { |name|
      self.const_get(name)
    }.select { |constant|
      constant.kind_of?(Class) && constant.ancestors.include?(Brut::CLI::Command) && constant.instance_methods.include?(:execute)
    }
  end

  def self.description(new_description=nil)
    if new_description.nil?
      return @description.to_s
    else
      @description = new_description
    end
  end

  def self.env_var(var_name=nil,purpose: nil)
    if var_name.nil? || purpose.nil?
      raise ArgumentError,"env_var requires a var_name and a purpose"
    end
    env_vars[var_name] = purpose
  end

  def self.env_vars
    @env_vars ||= {
      "BRUT_CLI_RAISE_ON_ERROR" => "if set, shows backtrace on errors"
    }
  end

  def self.default_command(new_command_name=nil)
    if new_command_name.nil?
      return @default_command || "help"
    else
      @default_command = new_command_name.nil? ? nil : new_command_name.to_s
    end
  end
  def self.opts
    self.option_parser
  end
  def self.option_parser
    @option_parser ||= OptionParser.new do |opts|
      opts.banner = "%{app} %{global_options} commands [command options] [args]"
    end
  end
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

  def self.default_env           = @default_env
  def self.requires_project_env? = @requires_project_env

  def self.configure_only!
    @configure_only = true
  end
  def self.configure_only? = !!@configure_only

  def initialize(global_options:,out:,err:,executor:)
    @global_options = global_options
    @out            = out
    @err            = err
    @executor       = executor
    if self.class.default_env
      @global_options.set_default(:env,self.class.default_env)
    end
  end

  def set_env_if_needed
    if self.class.requires_project_env?
      ENV["RACK_ENV"] = options.env
    end
  end

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

  def before_execute
  end

  def after_bootstrap
  end

  def configure!
  end

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
