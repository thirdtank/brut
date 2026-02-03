# An `IO`-like class that provides user-helpful output, to be used in place of `puts` and a logger. This is not replaceable for an IO.
#
# The problem this solves is allowing your CLI app to be clutter-free in the user's terminal, but to not hide information
# unnecessarily or make it unclear where the output is coming from.  Your CLI should use this class (or the methods that proxy
# to it, see `Brut::CLI::Commands::BaseCommand`) for all output and logging.
class Brut::CLI::Output

  def self.from_io(io_or_output)
    case io_or_output
    in Brut::CLI::Output
      io_or_output
    else
      self.new(io: io_or_output, app_name: $0)
    end
  end

  attr_reader :io
  attr_reader :prefix

  # Create a wrapper for the given IO that will use the given prefix
  #
  # @param [IO] io an IO where output should be sent, for example `$stdout`.
  # @param [String] app_name the name of the app that would be using this to generate output.
  def initialize(io:, app_name:)
    @io          = io
    @app_name    = app_name
    @sync_status = @io.sync
  end

  # @see https://ruby-doc.org/3.3.6/Kernel.html#method-i-puts
  def puts(*objects)
    if objects.empty?
      objects << ""
    end
    objects.each do |object|
      @io.puts(object)
    end
    nil
  end

  # Prints a string via `printf`, using the prefix.  This is useful for communciating to a human, but you need more power for
  # formatting than is afforded by {#puts}.
  #
  # @see https://ruby-doc.org/3.3.6/Kernel.html#method-i-printf
  def printf(format_string,*objects)
    @io.printf(format_string,*objects)
  end

  # Flush the underlying `IO`.
  def flush
    @io.flush
    self
  end
end
