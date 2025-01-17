# Renders an HTML `<select>`.
class Brut::FrontEnd::Components::Inputs::Select < Brut::FrontEnd::Components::Input
  # Creates the appropriate select input for the given {Brut::FrontEnd::Form} and input name.
  # Generally, you want to use this method over the initializer.
  #
  # @param [Brut::FrontEnd::Form} form The form that is being rendered. This method will consult this class to understand the requirements on this select so its HTML is generated correctly.
  # @param [String] input_name the name of the input, which should be a member of `form`
  # @param [Array<Object>] options An array of objects represented what is being selected. These can be any object and are ideally whatever domain object or data type you want on the backend to represent this selection.
  # @param [Object] selected_value The currently-selected value for the select. Can be `nil` if nothing is selected.
  # @param [Symbol|String] value_attribute the name of an attribute or no-parameter method that can be called on objects inside `options` to get the value to use in the select input.  This should be unique amongst the options, and is usually an id.
  # @param [Symbol|String] option_text_attribute the name of an attribute or no-parameter method that can be called on objects inside `options` to get the actual text of the option shown to the user.  This should probably allow for I18n.
  # @param [Integer] index if this input is part of an array, this is the index into that array. This is used to get the input's value.
  # @param [Hash] html_attributes any additional HTML attributes to include on the `<select>` element.
  # @param [false|true|Hash] include_blank configure how and if to include a blank element in the select. If this is false, there will be no blank element. If it's `true`, there will be one with no value nor text.  If this is a `Hash` it must contain a `value:` key and `text_content:` key to be used as the `value` attribute and option text content, respectively.
  def self.for_form_input(form:,
                          input_name:,
                          options:,
                          selected_value:,
                          include_blank: false,
                          value_attribute:,
                          option_text_attribute:,
                          index: nil,
                          html_attributes: {})
    default_html_attributes = {}
    index ||= 0
    input = form.input(input_name, index:)
    default_html_attributes["required"] = input.required
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
    Brut::FrontEnd::Components::Inputs::Select.new(
      name: name,
      options:,
      selected_value:,
      value_attribute:,
      option_text_attribute:,
      include_blank:,
      html_attributes: default_html_attributes.merge(html_attributes)
    )
  end
  # Create the element. See {.for_form_input} for documentation on these parameters.
  def initialize(name:,
                 options:,
                 include_blank: false,
                 selected_value:,
                 value_attribute:,
                 option_text_attribute:,
                 html_attributes:)
    @options               = options
    @include_blank         = IncludeBlank.from_param(include_blank)
    @selected_value        = selected_value
    @value_attribute       = value_attribute
    @option_text_attribute = option_text_attribute

    html_attributes["name"] = name
    @sanitized_attributes  = html_attributes.map { |key,value|
        [
          key.to_s.gsub(/[\s\"\'>\/=]/,"-"),
          value
        ]
    }.select { |key,value|
      !value.nil?
    }.to_h
  end

  def render
    html_tag(:select,**@sanitized_attributes) {
      options = @options.map { |option|
        value = option.send(@value_attribute)
        option_attributes = { value: value }
        if value == @selected_value
          option_attributes[:selected] = true
        end
        html_tag(:option,**option_attributes) {
          option.send(@option_text_attribute)
        }
      }
      if @include_blank
        options.unshift(html_tag(:option,**@include_blank.option_attributes) {
          @include_blank.text_content
        })
      end
      options.join("\n")
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
