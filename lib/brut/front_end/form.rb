require "forwardable"

module Brut::FrontEnd::Forms
  autoload(:InputDefinition, "brut/front_end/forms/input_definition")
  autoload(:ConstraintViolation, "brut/front_end/forms/constraint_violation")
  autoload(:ValidityState, "brut/front_end/forms/validity_state")
  autoload(:Input, "brut/front_end/forms/input")
end

module Brut::FrontEnd::FormInputDeclaration
  # Declares an input for this form.
  def input(name,attributes={})
    self.add_input_definition(
      Brut::FrontEnd::Forms::InputDefinition.new(**(attributes.merge(name: name)))
    )
  end

  def select(name,attributes={})
    self.add_input_definition(
      Brut::FrontEnd::Forms::SelectInputDefinition.new(**(attributes.merge(name: name)))
    )
  end

  def add_input_definition(input_definition)
    @input_definitions ||= {}
    @input_definitions[input_definition.name] = input_definition
    define_method input_definition.name do
      self[input_definition.name].value
    end
  end

  # Copy the inputs from another form into this one
  def inputs_from(other_class)
    if !other_class.respond_to?(:input_definitions)
      raise ArgumentError,"#{other_class} does not respond to #input_definitions - you cannot copy inputs from it"
    end
    other_class.input_definitions.each do |_name,input_definition|
      self.add_input_definition(input_definition)
    end
  end

  def input_definitions = @input_definitions || {}
end

class Brut::FrontEnd::Form

  include SemanticLogger::Loggable

  extend Brut::FrontEnd::FormInputDeclaration

  def self.routing(*)
    raise ArgumentError,"You called .routing on a form, but that form hasn't been configured with a route. You must do so in your route_config.rb file via the `form` method"
  end

  # Create an instance of this form, optionally initialized with
  # the given values for its params.
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
  def new? = @new

  # Access an input with the given name
  def [](input_name) = @inputs.fetch(input_name.to_s)

  # Returns true if this form has constraint violations.
  def constraint_violations? = !@inputs.values.all?(&:valid?)

  # Set a server-side constraint violation on a given input's name.
  def server_side_constraint_violation(input_name:, key:, context:{})
    self[input_name].server_side_constraint_violation(key,context)
  end

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

class Brut::FrontEnd::FormProcessingResponse

  def self.redirect_to(uri)                              = Redirect.new(uri)
  def self.render_page(page)                             = RenderPage.new(page)
  def self.render_component(component, http_status: 200) = RenderComponent.new(component,http_status)
  def self.send_http_status(http_status)                 = SendHttpStatusOnly.new(http_status)

  class Redirect < Brut::FrontEnd::FormProcessingResponse
    def initialize(uri)
      @uri = uri
    end

    def deconstruct_keys(keys) = { redirect: @uri }

  end

  class RenderPage < Brut::FrontEnd::FormProcessingResponse
    def initialize(page)
      @page = page
    end
    def deconstruct_keys(keys) = { page_instance: @page }
  end

  class RenderComponent < Brut::FrontEnd::FormProcessingResponse
    def initialize(component, http_status)
      @component   = component
      @http_status = http_status
    end
    def deconstruct_keys(keys) = { component_instance: @component, http_status: @http_status }
  end

  class SendHttpStatusOnly < Brut::FrontEnd::FormProcessingResponse
    def initialize(http_status)
      @http_status = http_status
    end
    def deconstruct_keys(keys) = { http_status: @http_status }
  end

end
