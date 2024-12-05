# Include this to enable methods to help with type checking.  Generally, you should not use this.
# You should only really use this if all of the following are true:
#
# * Passing in the wrong type Would Be Bad.
# * The developer passing it in would not easily be able to figure out what went wrong.
module Brut::Framework::FussyTypeEnforcement
  # Perform basic type checking, ideally inside a constructor when assigning ivars.  This is really intended for internal
  # classes that will not be exposed to user input, but rather to catch programmer bugs and programmer mis-use.
  #
  # @param [Object] value the value that is to be type-checked
  # @param [Class|Array<Object>] type_descriptor a class or an array of allowed values. If a class, `value` must be `kind_of?`
  #                                              that class. If an array, `value` must be one of the values in the array.
  # @param [String] variable_name_for_error_message the name of the variable begin type-checked so that error messages make sense
  # @param [true|false] required if true, the value may not be nil. If false, nil values are allowed. Note that in this context
  #                              a blank string counts as `nil`, so required strings may not be blank.
  # @param [Symbol|false] coerce if set, this is the symbol that will be used to coerce the value before type checking.
  #                              For example, if you accept a string but know it should be a number, pass in `:to_i`.
  # @return [Object] the value, if it matches the expectations of its type
  # @raise [ArgumentError] if the value doesn't confirm to the described type
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
