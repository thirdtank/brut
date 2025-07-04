class Brut::FrontEnd::Forms::RadioButtonGroupInput

  extend Forwardable

  # (see Brut::FrontEnd::Forms::Input#value)
  attr_reader :value

  # (see Brut::FrontEnd::Forms::Input#typed_value)
  attr_reader :typed_value

  # (see Brut::FrontEnd::Forms::Input#validity_state)
  attr_reader :validity_state

  # (see Brut::FrontEnd::Forms::Input#initialize)
  def initialize(input_definition:, value:, index:)
    @input_definition = input_definition
    @validity_state = Brut::FrontEnd::Forms::ValidityState.new
    @index = index
    if input_definition.array?
      value ||= []
    end
    self.value=(value)
  end

  def_delegators :"@input_definition", :name,
                                       :required,
                                       :array?

  # (see Brut::FrontEnd::Forms::Input#value=)
  def value=(new_value)
    new_value = new_value.to_s
    @typed_value = new_value.strip == "" ? nil : new_value

    value_missing = @typed_value.nil?
    missing = if self.required
                value_missing
              else
                false
              end

    @validity_state = Brut::FrontEnd::Forms::ValidityState.new(
      valueMissing: missing,
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
