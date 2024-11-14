# An InputDefinition captures metadata used to create an Input. Think of this
# as a template for creating inputs.  An Input has state, such as values and thus validity.
# An InputDefinition is immutable and defines inputs.
class Brut::FrontEnd::Forms::InputDefinition
  include Brut::Framework::FussyTypeEnforcement
  attr_reader :max,
              :maxlength,
              :min,
              :minlength,
              :name,
              :pattern,
              :required,
              :step,
              :type

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
  # the attributes used in an <INPUT> element in HTML.
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
    @name      = type!( name      , String                    , "name")
    @pattern   = type!( pattern   , String                    , "pattern")
    @required  = type!( required  , [true, false]             , "required", required: true)
    @step      = type!( step      , Numeric                   , "step")
    @type      = type!( type      , INPUT_TYPES_TO_CLASS.keys , "type", required: true)

    if @pattern.nil? && type == "email"
      @pattern = /^[^@]+@[^@]+\.[^@]+$/.source
    end
  end

  # Create an Input based on this defitition, initializing it with the given value.
  def make_input(value:)
    Brut::FrontEnd::Forms::Input.new(input_definition: self, value: value)
  end
end
class Brut::FrontEnd::Forms::SelectInputDefinition
  include Brut::Framework::FussyTypeEnforcement
  attr_reader :required, :name
  def initialize(name:, required: true)
    name = name.to_s
    @name     = type!( name      , String        , "name")
    @required = type!( required  , [true, false] , "required", required:true)
  end

  # Create an Input based on this defitition, initializing it with the given value.
  def make_input(value:)
    Brut::FrontEnd::Forms::SelectInput.new(input_definition: self, value: value)
  end
end
