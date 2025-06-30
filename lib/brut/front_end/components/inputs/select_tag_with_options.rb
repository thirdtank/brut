# Renders an HTML `<select>`.
class Brut::FrontEnd::Components::Inputs::SelectTagWithOptions < Brut::FrontEnd::Components::Input
  # Creates the appropriate select input for the given {Brut::FrontEnd::Form} and input name.
  # Generally, you want to use this method over the initializer.
  #
  # @param [Brut::FrontEnd::Form} form The form that is being rendered.
  #        This method will consult this class to understand the requirements
  #        on this select so its HTML is generated correctly.
  # @param [String] input_name the name of the input, which should be a member of `form`
  # @param [Array<Object>] options An array of objects represented what is being selected.
  #        These can be any object and are ideally whatever domain object or
  #        data type you want on the backend to represent this selection.
  # @param [Symbol|String] value_attribute the name of an attribute to determine an option's value.
  #        This will be called on each element of `options` to get the value used for the `<option>`'s
  #        `value` attribute.  The value returned by `value_attribute` should be unique amongst the
  #        `options` provided *and* be distinct from whatever `value` is used for `include_blank`.
  # @param [Symbol|String] option_text_attribute the name of an attribute to determine the text for an option.
  #        This will be called on each element of `options` to get the value used for the `<option>`'s
  #        text content.  The value returned by `option_text_attribute` need not be unique, though if it
  #        is not unique, it will certainly be confusing.
  # @param [Integer] index if this input is part of an array, this is the index into that array.
  #        This is used to get the input's value.
  # @param [Hash] html_attributes any additional HTML attributes to include on the `<select>` element.
  # @param [false|true|Hash] include_blank configure how and if to include a blank element in the select.
  #        If this is false, there will be no blank element. If it's `true`, there will be one with
  #        no value or text.  If this is a `Hash` it must contain a `value:` key and a `text_content:` key
  #        to be used as the `value` attribute and option text content, respectively.
  #
  # @return [Brut::FrontEnd::Components::Inputs::SelectTagWithOptions] the select input ready to be placed into a view.
  def initialize(form:,
                 input_name:,
                 options:,
                 include_blank: false,
                 value_attribute:,
                 option_text_attribute:,
                 index: nil,
                 html_attributes: {})
    html_attributes = html_attributes.map { |key,value| [ key.to_sym, value ] }.to_h
    default_html_attributes = {}
    index ||= 0
    input = form.input(input_name, index:)
    default_html_attributes[:required] = input.required
    if !form.new? && !input.valid?
      default_html_attributes["data-invalid"] = true
      input.validity_state.each do |constraint,violated|
        if violated
          default_html_attributes["data-#{constraint}"] = true
        end
      end
    end
    name = if input.array?
             "#{input.name}[]"
           else
             input.name
           end

    input_value = input.value

    @options                = options
    @include_blank          = IncludeBlank.from_param(include_blank)
    @value_attribute        = value_attribute
    @option_text_attribute  = option_text_attribute
    @html_attributes        = default_html_attributes.merge(html_attributes)
    @html_attributes[:name] = name

    if input_value.nil?
      @selected_value = nil # explicitly nothing is selected
    else
      if input_value.kind_of?(Array)
        raise "WTF: #{name}" # XXX?
      end
      option = options.detect { |option|
        input_value == option.send(@value_attribute)
      }
      if option.nil?
        raise ArgumentError, "selected_value #{input_value} was not the value for #{value_attribute} on any of the options: #{options.map { |option| option.send(value_attribute) }.join(', ')}"
      end
      @selected_value = option.send(@value_attribute)
    end
  end

  def view_template
    select(**@html_attributes) {
      if @include_blank
        option(**@include_blank.option_attributes) {
          @include_blank.text_content
        }
      end
      options = @options.each do |option|
        value = option.send(@value_attribute)
        option_attributes = { value: value }
        if value == @selected_value
          option_attributes[:selected] = true
        end
        option(**option_attributes) {
          option.send(@option_text_attribute)
        }
      end
    }
  end
private

  # @!visibility private
  class IncludeBlank
    attr_reader :text_content, :option_attributes
    def self.from_param(include_blank)
      if !include_blank
        return nil
      else
        self.new(include_blank)
      end
    end
    def initialize(include_blank)
      if include_blank == true
        @text_content = ""
        @option_attributes = {}
      elsif include_blank.kind_of?(Hash)
        if include_blank.key?(:value) && include_blank.key?(:text_content)
          @text_content = include_blank[:text_content]
          @option_attributes = { value: include_blank[:value] }
        else
          raise ArgumentError, "when include_blank: is a Hash, it must include both :value and :text_content as keys. Got: #{include_blank.keys.join(", ")}"
        end
      else
        raise ArgumentError,"include_blank: was a #{include_blank.class}. It should be true, false, nil, or a Hash"
      end
    end
  end
end
