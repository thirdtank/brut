# Like {Brut::FrontEnd::Forms::Input}, this models a `<SELECT>`'s current state and validity.
class Brut::FrontEnd::Forms::SelectInput

  extend Forwardable

  # (see Brut::FrontEnd::Forms::Input#value)
  attr_reader :value
  # (see Brut::FrontEnd::Forms::Input#validity_state)
  attr_reader :validity_state

  # (see Brut::FrontEnd::Forms::Input#initialize)
  def initialize(input_definition:, value:)
    @input_definition = input_definition
    @validity_state = Brut::FrontEnd::Forms::ValidityState.new
    self.value=(value)
  end

  def_delegators :"@input_definition", :name,
                                       :required

  # (see Brut::FrontEnd::Forms::Input#value=)
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

  # (see Brut::FrontEnd::Forms::Input#server_side_constraint_violation)
  def server_side_constraint_violation(key,context=true)
    @validity_state.server_side_constraint_violation(key: key, context: context)
  end

  # (see Brut::FrontEnd::Forms::Input#valid?)
  def valid? = @validity_state.valid?
end
