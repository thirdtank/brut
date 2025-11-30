# The context in which a command's execution is run.  This holds essentially all values that are input to
# the command, including parsed command line options, unparsed arguments, the UNIX environment, and
# the three s/O streams (stderr, stdout, stdin).
class Brut::CLI::Commands::ExecutionContext

  def initialize(
    argv: :default,
    options: :default,
    env: :default,
    stdout: :default,
    stderr: :default,
    stdin: :default,
    executor: :default
  )
    @argv     =                             argv == :default ? []                                                          : argv
    @options  =                          options == :default ? Brut::CLI::Options.new({})                                  : options
    @env      =                              env == :default ? {}                                                          : env
    @stdout   = Brut::CLI::Output.from_io(stdout == :default ? $stdout                                                     : stdout)
    @stderr   = Brut::CLI::Output.from_io(stderr == :default ? $stderr                                                     : stderr)
    @stdin    =                            stdin == :default ? $stdin                                                      : stdin
    @executor =                         executor == :default ? Brut::CLI::Executor.new(out: self.stdout, err: self.stderr) : executor
  end

  attr_reader :argv,
              :options,
              :env,
              :stdout,
              :stderr,
              :stdin,
              :executor

end
