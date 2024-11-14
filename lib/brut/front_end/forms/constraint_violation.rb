# Represents a specific error with a field.  A field can have any number of constraint violations
# to indicate what is wrong with it.  
class Brut::FrontEnd::Forms::ConstraintViolation

  CLIENT_SIDE_KEYS = [
    "bad_input",
    "custom_error",
    "pattern_mismatch",
    "range_overflow",
    "range_underflow",
    "step_mismatch",
    "too_long",
    "too_short",
    "type_mismatch",
    "value_missing",
  ]

  attr_reader :key, :context

  def initialize(key:,context:, server_side: :based_on_key)
    @key = key.to_s
    @client_side = CLIENT_SIDE_KEYS.include?(@key) && server_side != true
    @context = context || {}
    if !@context.kind_of?(Hash)
      raise "#{self.class} created for key #{key} with an invalid context: '#{context}/#{context.class}'. Context must be nil or a hash"
    end
  end

  def client_side? = @client_side
  def to_s = @key

  def to_json(*args)
    {
      key: self.key,
      context: self.context,
      client_side: self.client_side?
    }.to_json(*args)
  end
end
