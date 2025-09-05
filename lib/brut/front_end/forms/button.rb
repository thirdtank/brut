# Represents the current state of a particular button that is part of a form.
# Button's in this context don't really have state, but this allows the button to be
# modeled like any other form element.
class Brut::FrontEnd::Forms::Button < Brut::FrontEnd::Forms::Input
  # Create the input with the given definition and value
  # @param [Brut::FrontEnd::Forms::InputDefinition] input_definition
  # @param [String] value Value of the button, which would be submitted with the form. Note
  #                       that {Brut::FrontEnd::Forms::ButtonInputDefinition#make_input} will
  #                       default this value to `"true"`.
  def initialize(input_definition:, value:, index:)
    @input_definition = input_definition
    @validity_state = Brut::FrontEnd::Forms::ValidityState.new
    @index = index
    self.value=(value)
  end

  def value=(new_value)
    @value = new_value.to_s
    @typed_value = @value
  end
end
