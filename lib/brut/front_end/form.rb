require "forwardable"

# Holds classes used in form processing
module Brut::FrontEnd::Forms
  autoload(:InputDeclarations, "brut/front_end/forms/input_declarations")
  autoload(:InputDefinition, "brut/front_end/forms/input_definition")
  autoload(:SelectInputDefinition, "brut/front_end/forms/select_input_definition")
  autoload(:RadioButtonGroupInputDefinition, "brut/front_end/forms/radio_button_group_input_definition")
  autoload(:ConstraintViolation, "brut/front_end/forms/constraint_violation")
  autoload(:ValidityState, "brut/front_end/forms/validity_state")
  autoload(:Input, "brut/front_end/forms/input")
  autoload(:SelectInput, "brut/front_end/forms/select_input")
  autoload(:RadioButtonGroupInput, "brut/front_end/forms/radio_button_group_input")
end

# Base class for forms you create to process an HTML form. Generally, your form subclasses will only declare their inputs using
# methods from {Brut::FrontEnd::Forms::InputDeclarations}.  That said, you will likely create instances of forms as part of the logic
# for processing them or for testing.
class Brut::FrontEnd::Form

  extend Brut::FrontEnd::Forms::InputDeclarations

  # @!visibility private
  def self.routing(*)
    raise ArgumentError,"You called .routing on a form, but that form hasn't been configured with a route. You must do so in your route_config.rb file via the `form` method"
  end

  # Create an instance of this form, optionally initialized with
  # the given values for its params.  Because any values can be posted to a form endpoint, the initializer does not use kewyord
  # arguments.  Instead, it's initialize with whatever parameters were received.  This intializer will then set only those values
  # defined.
  def initialize(params: {})
    params = convert_to_string_or_nil(params.to_h)
    unknown_params = params.keys.map(&:to_s).reject { |key|
      self.class.input_definitions.key?(key)
    }
    if unknown_params.any?
      Brut.container.instrumentation.add_attributes(prefix: :brut, ignored_unknown_params: unknown_params.join(","))
    end
    @params = params.except(*unknown_params).map { |name,value|
        input_definition = begin
                             self.class.input_definitions[name] || self.class.input_definitions.fetch(name.to_s)
                           rescue KeyError
                             raise "cannot find input definition for '#{name}'. Have these: #{self.class.input_definitions.keys.inspect}"
                           end
      if value.kind_of?(Array)
        input_definition = begin
                             self.class.input_definitions[name] || self.class.input_definitions.fetch(name.to_s)
                           rescue KeyError
                             raise "cannot find input definition for '#{name}'. Have these: #{self.class.input_definitions.keys.inspect}"
                           end
        if input_definition.respond_to?(:type) && input_definition.type == "checkbox"
          if value.all? { it.to_s =~ /^\d+$/ }
            # the values represent the indexes of which checkboxes were checked
            new_values = []
            value.each do |index_as_string|
              index = Integer(index_as_string)
              new_values[index] = true
            end
            value = new_values.map { !!it }
          end
        end
      end
      [ name, value ]
    }.to_h

    @new = params_empty?(@params)
    @inputs = self.class.input_definitions.map { |name,input_definition|
      value = @params[name] || @params[name.to_sym]
      inputs = if value.kind_of?(Array)
                 value.map.with_index { |one_value, index|
                   input_definition.make_input(value: one_value, index:)
                 }
               else
                 [
                   input_definition.make_input(value:, index: nil)
                 ]
               end

      [ name, inputs ]
    }.to_h
  end

  # Returns true if this form represents a new, empty, untouched form. This is
  # useful for determining if this form has never been submitted and thus
  # any required values don't represent an intentional omission by the user.
  # Generally, don't override this. Instead, override {#params_empty?}.
  def new? = @new

  # Access an input with the given name
  #
  # @param [String|Symbol] input_name the name of the input, as passed to {Brut::FrontEnd::Forms::InputDeclarations#input} et. al.
  # @param [Integer] index the index of the input, when using arrays.
  # @return [Brut::FrontEnd::Forms::Input]
  def input(input_name, index: nil)
    index ||= 0
    inputs = self.inputs(input_name)
    input = inputs[index]
    if input.nil?
      input_definition = self.class.input_definitions.fetch(input_name.to_s)
      input = input_definition.make_input(value:"", index:)
      inputs[index] = input
    end
    input
  end

  # Return all inputs for the given name.
  # @param [String|Symbol] input_name the name of the input, as passed to {Brut::FrontEnd::Forms::InputDeclarations#input} et. al.
  # @return [Brut::FrontEnd::Forms::Input]
  def inputs(input_name)
    @inputs.fetch(input_name.to_s)
  rescue KeyError => ex
    raise Brut::Framework::Errors::Bug, "Form does not define the input '#{input_name}'. You must add this to your form. Found these inputs: #{@inputs.keys.join(', ')}"
  end

  # Returns true if this form has constraint violations.
  def constraint_violations? = !@inputs.values.flatten.all?(&:valid?)

  # Set a server-side constraint violation on a given input's name.
  #
  # @param [String|Symbol] input_name the name of the input, as passed to {Brut::FrontEnd::Forms::InputDeclarations#input} et. al.
  # @param [String] key the i18n key fragment representing the constraint. Assume this will be appended to `cv.ss.` in order
  # to form the entire key.
  # @param [Hash] context additional information about the violation, typically interpolated values for the I18n message.
  def server_side_constraint_violation(input_name:, key:, index: nil, context:{})
    index ||= 0
    self.input(input_name, index:).server_side_constraint_violation(key,context)
  end


  # Returns a map of any input with a constraint violation and the list of violations. The keys in the hash are input names and the
  # values are arrays of {Brut::FrontEnd::Forms::ValidityState} instances.
  #
  # @param [true|false] server_side_only if true, only server side constraints are returned.
  # @return [Hash<String|Array[2]>] a map of input names to arrays of constraint violations.  The first element in the
  # array is the validity state for the input, which is a {Brut::FrontEnd::Forms::ValidityState} instance.  The second
  # element is the index of the input in the array.  This index is used when you have more than one field with the same
  # name.
  #
  # @example iterating
  #   form.constraint_violations.each do |input_name, (constraint_violations,index)|
  #     # input_name is the input's name, e.g. "email"
  #     # constraint_violations is an array of {Brut::FrontEnd::Forms::ValidityState} instances, one for each
  #     #                       problem with the field's value
  #     # index is the index of the input in the array, e.g. 0  for the first email field, 1 for the second, etc.
  #   end
  #
  def constraint_violations(server_side_only: false)
    @inputs.map { |input_name, inputs|
      inputs.map.with_index { |input,index|
        if input.valid?
          nil
        else
          [
            input_name,
            [
              input.validity_state.select { |constraint|
                if server_side_only
                  !constraint.client_side?
                else
                  true
                end
              },
              index
            ]
          ]
        end
      }.compact
    }.select { !it.empty? }.flatten(1).to_h
  end

  # Template method that is used to determine if the params given to the form's initializer
  # represent an empty value.  By default, this returns true if those params were nil or empty.
  # You'd override this if there are values you want to initialize a form with that aren't considered
  # values provided by the user.  This can allow a form with values in it to be considered un-submitted.
  def params_empty?(params) = params.nil? || params.empty?

  # Return this form as a hash, which is a map of its parameters' current values. This is not simply
  # a filtered version of what was passed into the initializer.  This will only have the keys for the inputs
  # this form defines.  Those keys will be strings, not symbols.  The values will be
  # either `nil`, a String, or an array of strings.   Not every input defined by this form
  # will be represented as a key in the resulting hash—only those keys that were passed to the initializer.
  # @return [Hash<String,nil|String|Array<String>>] the form's params as a hash.
  def to_h
    @params.map { |key,value|
      [ key.to_s, value ]
    }.to_h
  end

private

  def convert_to_string_or_nil(hash)
    converted_hash = {}
    hash.each do |key,value|
      key = key.to_s
      case value
      in Hash       then converted_hash[key] = convert_to_string_or_nil(value)
      in String     then converted_hash[key] = RichString.new(value).to_s_or_nil
      in Numeric    then converted_hash[key] = value.to_s
      in TrueClass  then converted_hash[key] = "true"
      in FalseClass then converted_hash[key] = "false"
      in NilClass   then converted_hash[key] = nil
      in Array      then converted_hash[key] = value
      else
        if Brut.container.project_env.test?
          raise ArgumentError, "Got #{value.class} for #{key} in params hash, which is not expected"
        else
          Brut.container.instrumentation.add_event("convert_to_string_or_nil: Unknown class in params hash", class: value.class, key: key)
        end
      end
    end
    converted_hash
  end
end
