# A generic response to use when no built-in Brut construct will suffice. 
# This mirrors the response a Rack server is intended to produce, and serves 
# as merely a typed wrapper around that kind of response for the purposes of 
# understanding the intention of whoever is returning this.
#
# Once created, {#to_ary} will convert this into the array that Rack requires.
class Brut::FrontEnd::GenericResponse
  # Create a generic response.  
  #
  # @param [Brut::FrontEnd::HttpStatus|number] http_status the status to send. If omitted, a 200 is used.
  # Note that this value must be a valid HTTP status.
  # @param [Hash<String|String>] headers hash of headers to send with the response.
  # @param [String|Array<String>|IO|Enumerable] response_body the body of the response. This is passed
  # through directly to the underlying Rack server so it should be whatever Rack expects, which is generally
  # something that responds to `each`.
  def initialize(http_status: 200, headers: {}, response_body:)
    @response_body = response_body
    @headers       = headers
    @http_status   = Brut::FrontEnd::HttpStatus.new(http_status.to_i)
  end

  # Return this as an array suitable for use as a Rack response.
  #
  # @return [Array{String,3}] the response_body, headers, and http_status
  def to_ary
    [
      @http_status.to_i,
      @headers,
      @response_body,
    ]
  end
  alias deconstruct to_ary
end
