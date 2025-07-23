require "fileutils"

class MKBrut::Ops::Mkdir < MKBrut::Ops::BaseOp
  def initialize(path)
    @path = path
  end

  def call
    FileUtils.mkdir_p(@path, **fileutils_args)
  end

  def to_s = "Make Dir '#{@path}'"
end
