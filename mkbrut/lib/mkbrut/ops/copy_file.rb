require "fileutils"

class MKBrut::Ops::CopyFile < MKBrut::Ops::BaseOp
  def initialize(source, destination_root:)
    @source           = source
    @destination_root = destination_root
  end
  def call
    FileUtils.cp(@source, @destination_root / @source.basename, **fileutils_args)
  end
  def to_s = "Copy '#{@source}' to '#{@destination_root}'"
end
