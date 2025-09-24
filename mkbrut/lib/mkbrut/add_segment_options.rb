class MKBrut::AddSegmentOptions
  attr_reader :segment_name, :project_root

  def initialize(
    segment_name:,
    project_root:,
    dry_run: nil,
    versions: nil,
    **rest
  )
    if segment_name.nil?
      raise ArgumentError, "segment_name is required"
    end

    @segment_name =   segment_name
    @project_root =   project_root
    @dry_run      = !!dry_run
    @versions     =   versions
  end

  def dry_run? = @dry_run
end
