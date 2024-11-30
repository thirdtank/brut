require "optparse"
class Brut::CLI::Command
  include Brut::CLI::ExecutionResults
  include Brut::I18n::ForCLI

  def self.description(new_description=nil)
    if new_description.nil?
      return @description.to_s
    else
      @description = new_description
    end
  end
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
  def self.args(new_args=nil)
    if new_args.nil?
      return @args.to_s
    else
      @args = new_args
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
    }
  end
  def self.command_name = RichString.new(self.name.split(/::/).last).underscorized
  def self.name_matches?(string)
    self.command_name == string || self.command_name.to_s.gsub(/_/,"-") == string
  end
  def self.opts
    self.option_parser
  end
  def self.option_parser
    @option_parser ||= OptionParser.new do |opts|
      opts.banner = "%{app} %{global_options} #{command_name} %{command_options} %{args}"
    end
  end

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

  def self.default_env           = @default_env
  def self.requires_project_env? = @requires_project_env

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

  def system!(*args) = @executor.system!(*args)

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

  def delegate_to_command(command_klass)
    command = command_klass.new(command_options: options, global_options:, args:, out:, err:, executor: @executor)
    as_execution_result(command.execute)
  end

  def execute
    raise Brut::Framework::Errors::AbstractMethod
  end

  def before_execute
  end

  def set_env_if_needed
    if self.class.requires_project_env?
      ENV["RACK_ENV"] = options.env
    end
  end

  def handle_bootstrap_exception(ex)
    raise ex
  end

  def bootstrap!(project_root:, configure_only:)
    require "bundler"
    Bundler.require(:default, ENV["RACK_ENV"].to_sym)
    if configure_only
      require "#{project_root}/app/pre_boot"
      Brut::Framework.new(app: ::App.new)
    else
      require "#{project_root}/app/boot"
    end
    continue_execution
  end

private

  def options        = @command_options
  def global_options = @global_options
  def args           = @args
  def out            = @out
  def err            = @err

  def puts(...)
    warn("Your CLI apps should use out and err to produce terminal output, not puts", uplevel: 1)
    Kernel.puts(...)
  end

end
