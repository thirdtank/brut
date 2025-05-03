# Manages the interpretation of dev/test/prod. The canonical instance is available 
# via `Brut.container.project_env`.  Generally, you
# should avoid basing logic on this, or at least contain the conditional behavior
# to the configuration values. But, you do you.
class Brut::Framework::ProjectEnvironment
  # Create the project environment based on the string
  # @param [String] string_value value from e.g. `ENV["RACK_ENV"]` to use to set the environment
  # @raise [ArgumentError] if the string does not map to a known environment.
  def initialize(string_value)
    @value = case string_value
    when "development" then "development"
    when "test"        then "test"
    when "production"  then "production"
    else
      raise ArgumentError.new("'#{string_value}' is not a valid project environment")
    end
  end

  # @return [true|false] true is this is development
  def development? = @value == "development"
  # @return [true|false] true is this is test
  def test?        = @value == "test"
  # @return [true|false] true is this is production
  def production?  = @value == "production"

  def staging? = raise "Staging is a lie, please consider feature flags or literally any other way to manage in-development features of your app. I promise you, you will regret ever having to do anything with a staging server"

  # @return [String] the string value (which should be suitable for the constructor)
  def to_s = @value
end

