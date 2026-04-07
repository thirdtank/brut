# Extended by {Brut::FrontEnd::Form} to allow declaring inputs. This module creates methods per input on the form passed to your handlers. For example, if you have an `input :book_title`, then `form.book_title` will be available to access the value of the "book_title" input.
#
# There are two methods that could be created, per input. Examples below use
# `book_title` as the attribute name
#
# * `#book_title` - returns {Brut::FrontEnd::Forms::Input#value}, which is always a string.
# * `#book_title_coerced` - returns {Brut::FrontEnd::Forms::Input#typed_value}, which is always the correct type for the input **or `nil` if type coercion failed**. Only call this once you have checked for constraint violations
#
# For indexed parameters, the above methods require the index to be passed,
# e.g. `form.book_title_coerced(4)`.  For non-indexed parameters, the index may
# not be passed.
#
# Do not use this module directly. Instead, call {#input} or {#select}
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

  # Declares a named button for this form, which is required in order to have this button's name and
  # value sent to the back.  This will generate a `<button>` tag. To use `<input type="submit">`, {.input} should
  # be used instead.
  # @param [String] name The name of the button (used in the `name` attribute)
  def button(name)
    self.add_input_definition(
      Brut::FrontEnd::Forms::ButtonInputDefinition.new(name:)
    )
  end

  # Declares a select for this form, to be modeled via an HTML `<SELECT>` tag. Note that this will not define the values that appear
  # in the select.  That is done when the select is rendered, which you might do with a
  # {Brut::FrontEnd::Components::Inputs::Select}
  #
  # @param [String] name The name of the input (used in the `name` attribute)
  # @param [Hash] attributes Attributes to be used on the tag that represent its contraints. See {Brut::FrontEnd::Forms::SelectInputDefinition}
  def select(name,attributes={})
    self.add_input_definition(
      Brut::FrontEnd::Forms::SelectInputDefinition.new(**(attributes.merge(name: name)))
    )
  end

  # Declares a radio button group, which will manifest as one or more `<input type="radio">` tags that all use the same
  # value for their `name` attribute.  Unlike `input` or `select`, this method is declaring one or more actual
  # input tags.
  #
  # Note that this is not where you would define the possible values for the group. That is done in
  # {Brut::FrontEnd::Components::Inputs::RadioButton}.
  #
  # @param [String] name The name of the group (used in the `name` attribute)
  # @param [Hash] attributes Attributes to be used on the tag that represent its contraints. See {Brut::FrontEnd::Forms::RadioButtonGroupInputDefinition}
  def radio_button_group(name,attributes={})
    self.add_input_definition(
      Brut::FrontEnd::Forms::RadioButtonGroupInputDefinition.new(**(attributes.merge(name: name)))
    )
  end

  # @!visibility private
  def add_input_definition(input_definition)
    @input_definitions ||= {}
    @input_definitions[input_definition.name] = input_definition
    if input_definition.array?
      define_method input_definition.name do |index=nil|
        if index.nil?
          raise ArgumentError,"#{input_definition.name} is an array - you must provide an index to access one of its values"
        end
        self.input(input_definition.name, index:).value
      end
      define_method "#{input_definition.name}_coerced" do |index=nil|
        if index.nil?
          raise ArgumentError,"#{input_definition.name} is an array - you must provide an index to access one of its values"
        end
        self.input(input_definition.name, index:).typed_value
      end
      define_method "#{input_definition.name}_each" do |&block|
        self.inputs(input_definition.name).each_with_index do |input,i|
          block.(input.value,i)
        end
      end
      define_method "#{input_definition.name}_each_coerced" do |&block|
        self.inputs(input_definition.name).each_with_index do |input,i|
          block.(input.typed_value,i)
        end
      end
    else
      define_method input_definition.name do |index_that_should_be_omitted=nil|
        if !index_that_should_be_omitted.nil?
          raise ArgumentError,"#{input_definition.name} is not an array - do not provide an index when accessing its value"
        end
        self.input(input_definition.name, index: 0).value
      end
      define_method "#{input_definition.name}_coerced" do |index_that_should_be_omitted=nil|
        if !index_that_should_be_omitted.nil?
          raise ArgumentError,"#{input_definition.name} is not an array - do not provide an index when accessing its value"
        end
        self.input(input_definition.name, index: 0).typed_value
      end
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

  # Return a map of input names to input definitions
  #
  # @return [Hash<String,Brut::FrontEnd::Forms::InputDefinition>] a map of all defined input names to the definitions.
  #
  # @!visibility private
  def input_definitions
    @input_definitions ||= {}
  end
end

