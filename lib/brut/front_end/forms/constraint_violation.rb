# Represents a specific error with a field. Essentially wraps an i18n key fragment and interpolated values for use with other
# form-related classes.
class Brut::FrontEnd::Forms::ConstraintViolation

  # @return [String] the key fragment representing the violation
  attr_reader :key
  # @return [Hash] interpolated values useful in rendering the actual message
  attr_reader :context

  # Create a constraint violations
  #
  # @param [String|Symbol] key I18n key fragment representing this violation.
  # @param [Hash|nil] context interpolated values useful in rendering the message
  # @param [true|:based_on_key] server_side If `:based_on_key`, {#client_side?} will return true if `key` is in {ValidityState.KEYS}.
  # If `true`, {#client_side?} will return false no matter what.
  def initialize(key:,context:, server_side: :based_on_key)
    @key = key.to_s
    @client_side = Brut::FrontEnd::Forms::ValidityState::KEYS.include?(@key) && server_side != true
    @context = context || {}
    if !@context.kind_of?(Hash)
      raise "#{self.class} created for key #{key} with an invalid context: '#{context}/#{context.class}'. Context must be nil or a hash"
    end
  end

  # @return [true|false] true if this violation is a client-side violation
  def client_side? = @client_side
  def to_s = @key
end
