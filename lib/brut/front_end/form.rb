require "forwardable"

# Holds classes used in form processing
module Brut::FrontEnd::Forms
  autoload(:InputDeclarations, "brut/front_end/forms/input_declarations")
  autoload(:InputDefinition, "brut/front_end/forms/input_definition")
  autoload(:SelectInputDefinition, "brut/front_end/forms/select_input_definition")
  autoload(:ConstraintViolation, "brut/front_end/forms/constraint_violation")
  autoload(:ValidityState, "brut/front_end/forms/validity_state")
  autoload(:Input, "brut/front_end/forms/input")
  autoload(:SelectInput, "brut/front_end/forms/select_input")
end

# Base class for forms you create to process an HTML form. Generally, your form subclasses will only declare their inputs using
# methods from {Brut::FrontEnd::Forms::InputDeclarations}.  That said, you will likely create instances of forms as part of the logic
# for processing them or for testing.
class Brut::FrontEnd::Form

  include SemanticLogger::Loggable

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
      logger.info "Ignoring unknown params", keys: unknown_params
    end
    @params = params.except(*unknown_params)
    @new = params_empty?(@params)
    @inputs = self.class.input_definitions.map { |name,input_definition|
      input = input_definition.make_input(value: @params[name] || @params[name.to_sym])
      [ name, input ]
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
  # @return [Brut::FrontEnd::Forms::Input]
  def [](input_name)
    @inputs.fetch(input_name.to_s)
  rescue KeyError => ex
    raise Brut::Framework::Errors::Bug, "Form does not define the input '#{input_name}'. You must add this to your form"
  end

  # Returns true if this form has constraint violations.
  def constraint_violations? = !@inputs.values.all?(&:valid?)

  # Set a server-side constraint violation on a given input's name.
  #
  # @param [String|Symbol] input_name the name of the input, as passed to {Brut::FrontEnd::Forms::InputDeclarations#input} et. al.
  # @param [String] key the i18n key fragment representing the constraint. Assume this will be appended to `general.cv.be.` in order
  # to form the entire key.
  # @param [Hash] context additional information about the violation, typically interpolated values for the I18n message.
  def server_side_constraint_violation(input_name:, key:, context:{})
    self[input_name].server_side_constraint_violation(key,context)
  end

  # Returns a map of any input with a constraint violation and the list of violations. The keys in the hash are input names and the
  # values are arrays of {Brut::FrontEnd::Forms::ValidityState} instances.
  #
  # @param [true|false] server_side_only if true, only server side constraints are returned.
  # @return [Hash] map of input names to arrays of validity states
  #
  def constraint_violations(server_side_only: false)
    @inputs.map { |input_name, input|
      if input.valid?
        nil
      else
        [
          input_name,
          input.validity_state.select { |constraint|
            if server_side_only
              !constraint.client_side?
            else
              true
            end
          }
        ]
      end
    }.compact.to_h
  end

private

  def params_empty?(params) = params.nil? || params.empty?

  def convert_to_string_or_nil(hash)
    hash.each do |key,value|
      case value
      in Hash       then convert_to_string_or_nil(value)
      in String     then hash[key] = RichString.new(value).to_s_or_nil
      in Numeric    then hash[key] = value.to_s
      in TrueClass  then hash[key] = "true"
      in FalseClass then hash[key] = "false"
      in NilClass   then # it's fine
      else
        if Brut.container.project_env.test?
          raise ArgumentError, "Got #{value.class} for #{key} in params hash, which is not expected"
        else
          logger.warn("Got #{value.class} for #{key} in params hash, which is not expected")
        end
      end
    end
  end
end
