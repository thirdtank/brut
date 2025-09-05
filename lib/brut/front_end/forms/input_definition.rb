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
    "date"           => Date,
    "datetime-local" => Time,
    "email"          => String,
    "file"           => String,
    "hidden"         => String,
    "number"         => Numeric,
    "password"       => String,
    "radio"          => String,
    "range"          => String,
    "search"         => String,
    "submit"         => String,
    "tel"            => String,
    "text"           => String,
    "time"           => Time, # XXX
    "url"            => String,
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
  # @param [true|false] required true if this field is required, false otherwise. Default is `true` unless `type` is `"checkbox"` or `"submit"`.
  # @param [Integer] step Step value for ranged inputs.  A value that is not on a step is considered invalid.
  # @param [String] type the type of input to create. Should be a value from the HTML spec. Default is based on the value of `name`. If `email`, `type` is `email`. If `password` or `password_confirmation`, type is `password`. Otherwise `text`.
  # @param [true|false] array If true, the form will expect multiple values for this input.  The values will be available as an array. Any values omitted by the user will be present as empty strings.
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
    pattern: :based_on_type,
    required: :based_on_type,
    step: nil,
    type: nil,
    array: false
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
      required = case type
                 when "checkbox" then false
                 when "submit"   then false
                 else true
                 end
    end

    @max       = max
    @maxlength = type!( maxlength , Numeric                   , "maxlength")
    @min       = min
    @minlength = type!( minlength , Numeric                   , "minlength")
    @name      = type!( name      , String                    , "name", required: true)
    @required  = type!( required  , [true, false]             , "required", required: true)
    @step      = type!( step      , Numeric                   , "step")
    @type      = type!( type      , INPUT_TYPES_TO_CLASS.keys , "type", required: true)
    @array     = type!( array     , [true, false]             , "array", required: true)

    @pattern = if pattern == :based_on_type 
                 if type == "email"
                   /^[^@]+@[^@]+\.[^@]+$/.source
                 else
                   nil
                 end
               else
                 type!( pattern, String, "pattern" )
               end
  end

  def array? = @array


  # Create an Input based on this definition, initializing it with the given value.
  # @param [String] value the value to give this input initially.
  # @param [Integer] index the index of this input, if it is part of an array of
  # inputs. `nil` is allowed only if the input definition is not for an array.
  def make_input(value:, index:)
    Brut::FrontEnd::Forms::Input.new(input_definition: self, value:, index:)
  end
end
