class Brut::FrontEnd::HttpStatus
  def initialize(number)
    number = number.to_i
    if ((number < 100) || (number > 599))
      raise ArgumentError,"'#{number}' is not a known HTTP status code"
    end
    @number = number
  end

  def to_i = @number
  def to_s = to_i.to_s

  def ==(other)
    self.class == other.class && self.to_i == other.to_i
  end
end
