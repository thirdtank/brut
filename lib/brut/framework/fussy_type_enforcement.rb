# Include this to enable methods to help with type checking.  Generally, you should not use this
# unless there is a real concern that someone will pass the wrong type in and it would not be obvious
# that they made this mistake.  Of note, this is preferred for widely used classes instead of trying
# to convert arguments to whatever type the class needs.
module Brut::Framework::FussyTypeEnforcement
  # Perform basic type checking, ideally inside a constructor when assigning ivars
  #
  # value:: the value that was given
  # type_descriptor:: a class or an array of allowed values. If a class, value must be kind_of? that class. If an array,
  #                   value must be one of the values in the array.
  # variable_name_for_error_message:: the name of the variable so that error messages make sense
  # required:: if true, the value may not be nil. If false, nil values are allowed and no real type checking is done. Note that a
  #            string that is blank counts as nil, so a require string must not be blank.
  # coerce:: if given, this is the symbol that will be used to coerce the value before type checking
  def type!(value,type_descriptor,variable_name_for_error_message, required: false, coerce: false)

    value_blank = value.nil? || ( value.kind_of?(String) && value.strip == "" )

    if !required && value_blank
      return value
    end

    if required && value_blank
      raise ArgumentError.new("'#{variable_name_for_error_message}' must have a value")
    end

    if type_descriptor.kind_of?(Class)
      coerced_value = coerce ? value.send(coerce) : value
      if !coerced_value.kind_of?(type_descriptor)
        class_description = if coerce
                              "but was a #{value.class}, coerced to a #{coerced_value.class} via #{coerce}"
                            else
                              "but was a #{value.class}"
                            end
        raise ArgumentError.new("'#{variable_name_for_error_message}' must be a #{type_descriptor}, #{class_description} (value as a string is #{value})")
      end
      value = coerced_value
    elsif type_descriptor.kind_of?(Array)
      if !type_descriptor.include?(value)
        description_of_values = type_descriptor.map { |value|
          "#{value} (a #{value.class})"
        }.join(", ")
        raise ArgumentError.new("'#{variable_name_for_error_message}' must be one of #{description_of_values}, but was a #{value.class} (value as a string is #{value})")
      end
    else
      raise ArgumentError.new("Use of type! with a #{type_descriptor.class} (#{type_descriptor}) is not supported")
    end
    value
  end
end
