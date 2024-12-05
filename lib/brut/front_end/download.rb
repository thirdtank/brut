# Represents a file the browser is going to download. This can be returned from a handler to initiate a download instead of rendering
# content.
class Brut::FrontEnd::Download

  # @return [Object] the data to be sent in the download
  attr_reader :data

  # Create a download
  #
  # @param [String] filename The name (or base name) of the file name that will be downloaded.
  # @param [Object] data the data/contents of the file to download
  # @param [String] content_type the MIME content type to let the browser know what type of file this is.
  # @param [Time] timestamp if given, will be used with `filename` to set the filename of the file.  This is useful if your users will
  #               download the same file mulitple times but you want to make each name different and meaningful.
  def initialize(filename:,data:,content_type:,timestamp: false)
    @filename     = filename
    @data         = data
    @content_type = content_type
    @timestamp    = timestamp
  end

  # Access the necessary HTTP headers to allow this file to be downloaded
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
