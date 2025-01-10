# Defines a `<select>` for a form, but not it's current runtime state.  {Brut::FrontEnd::Forms::SelectInput} is used to understand the current state or value of a select.
#
# Note that a select input definition is defining an HTML `<select>`, not a generic attribute.  Thus, the only constraints you can place on
# an input are those that the browser supports.  If your form needs server side validation, you can accomplish that in a lot of ways,
# such as implementing a {Brut::BackEnd::Validators::FormValidator}, or calling
# {Brut::FrontEnd::Form#server_side_constraint_violation} directly.
class Brut::FrontEnd::Forms::SelectInputDefinition
  include Brut::Framework::FussyTypeEnforcement
  attr_reader :required, :name
  # Create the input definition
  # @param [String] name Name of the input (required)
  # @param [true|false] required true if this field is required, false otherwise. Default is `true`.
  # @param [true|false] array If true, the form will expect multiple values for this input.  The values will be available as an array. Any values omitted by the user will be present as empty strings.
  def initialize(name:, required: true, array: false)
    name = name.to_s
    @name     = type!( name      , String        , "name",     required: true)
    @required = type!( required  , [true, false] , "required", required: true)
    @array    = type!( array     , [true, false] , "array", required: true)
  end

  def array? = @array

  # Create an Input based on this defitition, initializing it with the given value.
  def make_input(value:)
    Brut::FrontEnd::Forms::SelectInput.new(input_definition: self, value: value)
  end
end
