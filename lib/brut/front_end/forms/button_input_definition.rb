# Defines a button to be used to submit a form (as opposed to an `<input type="submit">`).
# This is needed when the name/value of the button should be submitted witih the form.
class Brut::FrontEnd::Forms::ButtonInputDefinition
  include Brut::Framework::FussyTypeEnforcement

  attr_reader :name

  # Create a ButtonInputDefinition.
  #
  # @param [String] name Name of the button (required)
  # @param [true|false] array If true, the form will expect multiple values for this input.  The values will be available as an array. Any values omitted by the user will be present as empty strings.
  #
  # @see https://developer.mozilla.org/en-US/docs/Web/HTML/Element/button BUTTON Element
  def initialize(
    name:,
    array: false
  )
    name  = name.to_s
    @name  = type!(name,  String,        "name",  required: true)
    @array = type!(array, [true, false], "array", required: true)
  end

  def array? = @array


  # Create an Input based on this definition, initializing it with the given value.
  # @param [String] value the value to give this input initially. If this is blank,
  #                 the button's value will be `"true"`.
  # @param [Integer] index the index of this input, if it is part of an array of
  #                  inputs. `nil` is allowed only if the input definition is not for an array.
  def make_input(value:, index:)
    if value.to_s.strip == ""
      value = "true"
    end
    Brut::FrontEnd::Forms::Button.new(input_definition: self, value:, index:)
  end
end
