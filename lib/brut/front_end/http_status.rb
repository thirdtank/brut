# Wrapper around an HTTP status, that can also normalize strings that contain status codes.
class Brut::FrontEnd::HttpStatus
  # Create an http status
  #
  # @param [Integer|String] number the status code. `to_i` is used to coerce this into a number.
  #
  # @raise [ArgumentError] if the value is lower than 100 or greater than 599. Note that the spec allows any value in that range to be
  #                        considered a valid HTTP status code
  def initialize(number)
    number = number.to_i
    if ((number < 100) || (number > 599))
      raise ArgumentError,"'#{number}' is not a known HTTP status code"
    end
    @number = number
  end

  # @return [Number] the value as a number
  def to_i = @number
  # @return [String] the value as a string
  def to_s = to_i.to_s

  # @return [true|false] true if the other object has the same class as this and has the same numeric representation
  def ==(other)
    self.class == other.class && self.to_i == other.to_i
  end
end
