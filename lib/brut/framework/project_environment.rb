class Brut::Framework::ProjectEnvironment
  def initialize(string_value)
    @value = case string_value
    when "development" then "development"
    when "test"        then "test"
    when "production"  then "production"
    else
      raise ArgumentError.new("'#{string_value}' is not a valid project environment")
    end
  end

  def development? = @value == "development"
  def test?        = @value == "test"
  def production?  = @value == "production"

  def to_s = @value
end

