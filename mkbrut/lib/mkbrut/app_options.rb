class MKBrut::AppOptions
  attr_reader :app_name, :app_id, :prefix, :organization, :demo, :versions, :segments

  def initialize(
    app_name:,
    app_id: nil,
    prefix: nil,
    dry_run: nil,
    organization: nil,
    demo: false,
    versions: nil,
    **rest
  )
    if app_name.nil?
      raise ArgumentError, "app_name is required"
    end

    @app_name     =   app_name
    @app_id       =   app_id       || MKBrut::AppId.from_app_name(@app_name)
    @prefix       =   prefix       || MKBrut::Prefix.from_app_id(@app_id)
    @organization =   organization || @app_id
    @dry_run      = !!dry_run
    @demo         = !!demo
    @versions     =   versions
    @segments     = rest.map { |key,value|
      if key =~ /^segment-(.+)$/ && value
        $1
      else
        nil
      end
    }.compact
  end

  def dry_run? = @dry_run
  def demo?    = @demo
end
