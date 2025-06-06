# Defines a radio button group for a form, but not it's runtime state (which includes how many radio buttons would need to be
# rendered).  See {Brut::FrontEnd::Forms::RadioButtonInput}.
#
# Note that this ultimately defines the contents for a `<input type="radio">` tag, so the constraints you can place are only those
# supported by the browser.  Also note that arrays of radio button groups are not currently supported.
class Brut::FrontEnd::Forms::RadioButtonGroupInputDefinition
  include Brut::Framework::FussyTypeEnforcement
  attr_reader :required, :name
  # Create the input definition
  # @param [String] name Name of the input (required)
  # @param [true|false] required true if this field is required, false otherwise. Default is `true`.
  # @param [true|false] array If true, an error is raised as this is not yet supported
  def initialize(name:, required: true, array: false)
    name = name.to_s
    @name     = type!( name      , String        , "name",     required: true)
    @required = type!( required  , [true, false] , "required", required: true)
    @array    = type!( array     , [true, false] , "array", required: true)
    if @array
      raise Brut::Framework::Errors::NotImplemented, "Arrays of radio button groups are not yet supported"
    end
  end

  def array? = @array

  # Create an Input based on this defitition, initializing it with the given value.
  def make_input(value:, index:)
    Brut::FrontEnd::Forms::RadioButtonGroupInput.new(input_definition: self, value:, index:)
  end
end
