# Thrown when an expected parameter in e.g. a path or a method invocation is
# not available.
class Brut::Framework::Errors::MissingParameter < Brut::Framework::Error
  def initialize(missing_param, params_received:, context:)
    @missing_param = missing_param
    super("Parameter '#{missing_param}' was not available. Received params: '#{params_received.empty? ? 'no params' : params_received.join(', ')}'. #{context}")
  end
end
