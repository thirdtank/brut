# Raised when Brut configuration is missing an expected value.  This is mostly raised when values that must be set per app
# have not been set.
class Brut::Framework::Errors::MissingConfiguration < Brut::Framework::Error
  # Create the exception
  #
  # @param [String|Symbol] config_name the name of the missing configuration parameter
  # @param [String] context Any additional context to understand the error
  def initialize(config_name, context)
    super("Configuration parameter '#{config_name}' did not have a value, but was expected to. #{context}")
  end
end
