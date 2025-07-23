require "delegate"
class PrefixedIO < Delegator
  def initialize(io, prefix)
    @io     = io
    @prefix = "[ #{prefix} ] "
  end

  def __getobj__ = @io

  def puts(*args)
    args.each do |arg|
      @io.puts(@prefix + arg.to_s)
    end
  end

end
