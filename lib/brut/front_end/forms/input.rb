# An Input is a stateful object representing a specific input and its value
# during the course of a form submission process. In particular, it wraps a value
# and a {Brut::FrontEnd::Forms::ValidityState}. These are mutable, whereas the wrapped {Brut::FrontEnd::Forms::InputDefinition} is not.
class Brut::FrontEnd::Forms::Input

  extend Forwardable

  # @return [String] the input's value
  attr_reader :value
  # @return [Brut::FrontEnd::Forms::ValidityState] Validity state that captures the current constraint violations, if any
  attr_reader :validity_state

  # Create the input with the given definition and value
  # @param [Brut::FrontEnd::Forms::InputDefinition] input_definition
  # @param [String] value
  def initialize(input_definition:, value:)
    @input_definition = input_definition
    @validity_state = Brut::FrontEnd::Forms::ValidityState.new
    self.value=(value)
  end

  def_delegators :"@input_definition", :max,
                                       :maxlength,
                                       :min,
                                       :minlength,
                                       :name,
                                       :pattern,
                                       :required,
                                       :step,
                                       :type

  # Set the value, analyzing it for constraint violations based on the input's definition.
  # This is essentially duplicating whatever the browser would be doing on its end, thus allowing
  # for server-side validation of client-side constraints.
  #
  # When this method completes, the value of {#validity_state} could change.
  #
  # @param [String] new_value the value for the input
  def value=(new_value)
    value_missing = new_value.nil? || (new_value.kind_of?(String) && new_value.strip == "")
    missing = if self.required
                value_missing
              else
                false
              end
    too_short = if self.minlength && !value_missing
                  new_value.length < self.minlength
                else
                  false
                end

    too_long = if self.maxlength && !value_missing
                 new_value.length > self.maxlength
               else
                 false
               end

    type_mismatch = false # TBD

    range_overflow = if self.max && !value_missing && !type_mismatch
                       new_value.to_i > self.max
                     else
                       false
                     end

    range_underflow = if self.min && !value_missing && !type_mismatch
                       new_value.to_i < self.min
                     else
                       false
                     end

    pattern_mismatch = false
    step_mismatch = false

    @validity_state = Brut::FrontEnd::Forms::ValidityState.new(
      value_missing: missing,
      too_short: too_short,
      too_long: too_short,
      range_overflow: range_overflow,
      range_underflow: range_underflow,
      pattern_mismatch: pattern_mismatch,
      step_mismatch: step_mismatch,
      type_mismatch: type_mismatch,
    )
    @value = new_value
  end

  # Set a server-side constraint violation on this input.  This is essentially arbitrary, but note
  # that `key` should not be a key used for client-side validations.
  #
  # @param [String|Symbol] key the I18n key fragment that describes the server side constraint violation
  # @param [Hash|nil] context any interpolations required to render the message
  def server_side_constraint_violation(key,context=true)
    @validity_state.server_side_constraint_violation(key: key, context: context)
  end

  # @return [true|false] true if the underlying {#validity_state} has no constraint violations
  def valid? = @validity_state.valid?
end
