# Defines an input for a form, but not it's current runtime state.  {Brut::FrontEnd::Forms::Input} is used to understand the current
# state or value of an input.
#
# Note that an input definition is defining an HTML `<input>`, not a generic attribute.  Thus, the only constraints you can place on
# an input are those that the browser supports.  If your form needs server side validation, you can accomplish that in a lot of ways,
# such as implementing a {Brut::BackEnd::Validators::FormValidator}, or calling
# {Brut::FrontEnd::Form#server_side_constraint_violation} directly.
class Brut::FrontEnd::Forms::InputDefinition
  include Brut::Framework::FussyTypeEnforcement

  attr_reader :max
  attr_reader :maxlength
  attr_reader :min
  attr_reader :minlength
  attr_reader :name
  attr_reader :pattern
  attr_reader :required
  attr_reader :step
  attr_reader :type

  # @!visibility private
  INPUT_TYPES_TO_CLASS = {
    "checkbox"       => String,
    "color"          => String,
    "date"           => String,
    "datetime-local" => String,
    "email"          => String,
    "file"           => String,
    "hidden"         => String,
    "month"          => String,
    "number"         => Numeric,
    "password"       => String,
    "radio"          => String,
    "range"          => String,
    "search"         => String,
    "tel"            => String,
    "text"           => String,
    "time"           => String,
    "url"            => String,
    "week"           => String,
  }

  # Create an InputDefinition. This should very closely mirror
  # the attributes used in an `<INPUT>` element in HTML. The idea is to be able to create HTML that validates its values the same as
  # we can in Ruby so that client side validations can be safely used for user experience, but also re-executed server side.
  #
  #
  # @param [Integer|Date|Time] min Minimum value allowed by the input. Not relevat to all `type`s.
  # @param [Integer|Date|Time] max Maximum value allowed by the input. Not relevat to all `type`s.
  # @param [Integer] minlength Minimum length of the value allowed.
  # @param [Integer] maxlength Maximum length of the value allowed.
  # @param [String] name Name of the input (required)
  # @param [Regexp] pattern that the value must match. Note that this technically must be a regular expression that works for both Ruby and JavaScript, so don't get fancy.
  # @param [true|false] required true if this field is required, false otherwise. Default is `true` unless `type` is `"checkbox"`.
  # @param [Integer] step Step value for ranged inputs.  A value that is not on a step is considered invalid.
  # @param [String] type the type of input to create. Should be a value from the HTML spec. Default is based on the value of `name`. If `email`, `type` is `email`. If `password` or `password_confirmation`, type is `password`. Otherwise `text`.
  #
  #
  # @see https://developer.mozilla.org/en-US/docs/Web/HTML/Element/input INPUT Element
  # @see https://developer.mozilla.org/en-US/docs/Web/HTML/Element/input#input_types Input types
  def initialize(
    max: nil,
    maxlength: nil,
    min: nil,
    minlength: nil,
    name: nil,
    pattern: nil,
    required: :based_on_type,
    step: nil,
    type: nil
  )
    name = name.to_s
    type = if type.nil?
             case name
             when "email" then "email"
             when "password" then "password"
             when "password_confirmation" then "password"
             else
               "text"
             end
           else
             type
           end

    type = type.to_s
    if required == :based_on_type
      required = type != "checkbox"
    end

    @max       = type!( max       , Numeric                   , "max")
    @maxlength = type!( maxlength , Numeric                   , "maxlength")
    @min       = type!( min       , Numeric                   , "min")
    @minlength = type!( minlength , Numeric                   , "minlength")
    @name      = type!( name      , String                    , "name", required: true)
    @pattern   = type!( pattern   , String                    , "pattern")
    @required  = type!( required  , [true, false]             , "required", required: true)
    @step      = type!( step      , Numeric                   , "step")
    @type      = type!( type      , INPUT_TYPES_TO_CLASS.keys , "type", required: true)

    if @pattern.nil? && type == "email"
      @pattern = /^[^@]+@[^@]+\.[^@]+$/.source
    end
  end

  # Create an Input based on this definition, initializing it with the given value.
  def make_input(value:)
    Brut::FrontEnd::Forms::Input.new(input_definition: self, value: value)
  end
end
