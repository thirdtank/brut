require "fileutils"

class Brut::CLI::Apps::New::Ops::Mkdir < Brut::CLI::Apps::New::Ops::BaseOp
  def initialize(path)
    @path = path
  end

  def call
    FileUtils.mkdir_p(@path, **fileutils_args)
  end

  def to_s = "Make Dir '#{@path}'"
end
