# Raised when an expected parameter in e.g. a path or a method invocation is
# not available.  This allows classes to give a better error message than
# the one provided by standard library exceptions like `KeyError`
class Brut::Framework::Errors::MissingParameter < Brut::Framework::Error
  # Create the exception
  # @param [String|Symbol] missing_param the name of the missing parameter.
  # @param [Array<String|Symbol>] params_received the parameters that were received in the context that generated this error
  # @param [String] context Any additional context to understand the error
  def initialize(missing_param, params_received:, context:)
    super("Parameter '#{missing_param}' was not available. Received params: '#{params_received.empty? ? 'no params' : params_received.join(', ')}'. #{context}")
  end
end
