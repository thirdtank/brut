# An Input is a stateful object representing a specific input and its value
# during the course of a form submission process. In particular, it wraps a value
# and a ValidityState. These are mutable, whereas the wrapped InputDefinition is not.
class Brut::FrontEnd::Forms::Input

  extend Forwardable

  attr_reader :value, :validity_state

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
  def server_side_constraint_violation(key,context=true)
    @validity_state.server_side_constraint_violation(key: key, context: context)
  end

  def valid? = @validity_state.valid?
end
class Brut::FrontEnd::Forms::SelectInput

  extend Forwardable

  attr_reader :value, :validity_state

  def initialize(input_definition:, value:)
    @input_definition = input_definition
    @validity_state = Brut::FrontEnd::Forms::ValidityState.new
    self.value=(value)
  end

  def_delegators :"@input_definition", :name,
                                       :required

  def value=(new_value)
    value_missing = new_value.nil? || (new_value.kind_of?(String) && new_value.strip == "")
    missing = if self.required
                value_missing
              else
                false
              end

    @validity_state = Brut::FrontEnd::Forms::ValidityState.new(
      value_missing: missing,
    )
    @value = new_value
  end

  # Set a server-side constraint violation on this input.  This is essentially arbitrary, but note
  # that `key` should not be a key used for client-side validations.
  def server_side_constraint_violation(key,context=true)
    @validity_state.server_side_constraint_violation(key: key, context: context)
  end

  def valid? = @validity_state.valid?
end
