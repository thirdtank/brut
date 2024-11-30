class Brut::CLI::Output
  def initialize(io:, prefix:)
    @io          = io
    @prefix      = prefix
    @sync_status = @io.sync
  end

  def puts_no_prefix(*objects)
    @io.puts(*objects)
  end

  def puts(*objects)
    if objects.empty?
      objects << ""
    end
    objects.each do |object|
      @io.puts(@prefix + object.to_s)
    end
    nil
  end

  def print(*objects)
    @io.print(*objects)
  end

  def printf(format_string,*objects)
    @io.printf(@prefix + format_string,*objects)
  end
  def printf_no_prefix(format_string,*objects)
    @io.printf(format_string,*objects)
  end

  def flush
    @io.flush
    self
  end
end
