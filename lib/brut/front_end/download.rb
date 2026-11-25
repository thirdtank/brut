# Represents a file the browser is going to download. This can be returned from a handler to initiate a download instead of rendering
# content.
class Brut::FrontEnd::Download

  # @return [Object] the data to be sent in the download
  attr_reader :data

  # Create a download
  #
  # @param [String] filename The name (or base name) of the file name that will be downloaded. 
  #        Does not need to be ASCII, however nonsense characters, backslashes, carriage returns, etc
  #        will be rejected with an `ArgumentError`.
  # @param [Object] data the data/contents of the file to download
  # @param [String] content_type the MIME content type to let the browser know what type of file this is.
  # @param [Time] timestamp if given, will be used with `filename` to set the filename of the file.  This is useful if your users will
  #               download the same file mulitple times but you want to make each name different and meaningful.
  def initialize(filename:,data:,content_type:,timestamp: false)
    if filename =~ INVALID_CHARACTER_REGXP
      raise ArgumentError, "filename '#{filename}' cannot contain control characters, backslashes, or other oddball things"
    end

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
      "content-disposition" => content_disposition(filename),
      "content-type" => @content_type,
    }
  end

private

  INVALID_CHARACTER_REGXP = /[[:cntrl:]"'\\]/ # https://regex101.com/r/DOdSeJ/1

  def content_disposition(filename)
    if filename.ascii_only?
      "attachment; filename=\"#{filename}\""
    else
      encoded = ERB::Util.url_encode(filename)
      "attachment; filename*=UTF-8''#{encoded}"
    end
  end

end
