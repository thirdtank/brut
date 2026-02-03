# The context in which a command's execution is run.  This holds essentially all values that are input to
# the command, including parsed command line options, unparsed arguments, the UNIX environment, and
# the three I/O streams (stderr, stdout, stdin).
class Brut::CLI::Commands::ExecutionContext

  def initialize(
    argv: :default,
    options: :default,
    env: :default,
    stdout: :default,
    stderr: :default,
    stdin: :default,
    executor: :default,
    logger: :default
  )
    @argv       =    argv == :default ? []                                                          : argv
    @options  =   options == :default ? Brut::CLI::Options.new({})                                  : options
    @env      =       env == :default ? {}                                                          : env
    @stdout   =    stdout == :default ? $stdout                                                     : stdout
    @stderr   =    stderr == :default ? $stderr                                                     : stderr
    @stdin    =     stdin == :default ? $stdin                                                      : stdin
    @logger   =    logger == :default ? Brut::CLI::Logger.new(app_name: $0, stdout: @stdout, stderr: @stderr) : logger
    @executor =  executor == :default ? Brut::CLI::Executor.new(logger: @logger, out: self.stdout, err: self.stderr) : executor

    @logger.level         = @options.log_level
    @logger.log_file      = @options.log_file
    @logger.log_to_stdout = @options.log_stdout?
  end

  attr_reader :argv,
              :options,
              :env,
              :stdout,
              :stderr,
              :stdin,
              :executor,
              :logger

end
