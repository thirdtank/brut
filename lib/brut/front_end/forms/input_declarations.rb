# Extended by {Brut::FrontEnd::Form} to allow declaring inputs. Do not use this module directly. Instead, call {#input} or {#select}
# from within your form's class definition.
module Brut::FrontEnd::Forms::InputDeclarations
  # Declares an input for this form, to be modeled via an HTML `<INPUT>` tag.
  #
  # @param [String] name The name of the input (used in the `name` attribute)
  # @param [Hash] attributes Attributes to be used on the tag that represent its contraints. See {Brut::FrontEnd::Forms::InputDefinition}
  def input(name,attributes={})
    self.add_input_definition(
      Brut::FrontEnd::Forms::InputDefinition.new(**(attributes.merge(name: name)))
    )
  end

  # Declares a select for this form, to be modeled via an HTML `<SELECT>` tag. Note that this will not define the values that appear
  # in the select.  That is done when the select is rendered, which you might do with
  # {Brut::FrontEnd::Components::Inputs::Select.for_form_input}
  #
  # @param [String] name The name of the input (used in the `name` attribute)
  # @param [Hash] attributes Attributes to be used on the tag that represent its contraints. See {Brut::FrontEnd::Forms::SelectInputDefinition}
  def select(name,attributes={})
    self.add_input_definition(
      Brut::FrontEnd::Forms::SelectInputDefinition.new(**(attributes.merge(name: name)))
    )
  end

  # @!visibility private
  def add_input_definition(input_definition)
    @input_definitions ||= {}
    @input_definitions[input_definition.name] = input_definition
    define_method input_definition.name do
      self[input_definition.name].value
    end
  end

  # Copy the inputs from another form into this one. This is useful when one form should have identical inputs from another, plus a
  # few of its own.
  #
  # @param [Class] other_class a subclass of {Brut::FrontEnd::Form}.
  def inputs_from(other_class)
    if !other_class.respond_to?(:input_definitions)
      raise ArgumentError,"#{other_class} does not respond to #input_definitions - you cannot copy inputs from it"
    end
    other_class.input_definitions.each do |_name,input_definition|
      self.add_input_definition(input_definition)
    end
  end

  # @!visibility private
  def input_definitions = @input_definitions || {}
end

