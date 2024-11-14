class Brut::FrontEnd::Download

  attr_reader :data

  def initialize(filename:,data:,content_type:,timestamp: false)
    @filename     = filename
    @data         = data
    @content_type = content_type
    @timestamp    = timestamp
  end

  def headers
    filename = if @timestamp
                 Time.now.strftime("%Y-%m-%dT%H-%M-%S") + "-" + @filename
               else
                 @filename
               end
    {
      "content-disposition" => "attachment; filename=\"#{filename}\"",
      "content-type" => @content_type,
    }
  end
end
