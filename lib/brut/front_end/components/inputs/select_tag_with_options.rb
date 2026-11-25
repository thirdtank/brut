# Renders an HTML `<select>`.
class Brut::FrontEnd::Components::Inputs::SelectTagWithOptions < Brut::FrontEnd::Components::Input
  # Creates the appropriate select input for the given {Brut::FrontEnd::Form} and input name.
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
    input = form_input(form:, input_name:, index:, 
                       clazz: Brut::FrontEnd::Forms::SelectInput)

    @html_attributes = Brut::FrontEnd::Forms::HtmlAttributes.new(
      input:,
      initial_attributes: html_attributes,
      forbidden_attributes: {
        multiple: "Multi-selects are not supported by Brut",
      }
    ).with_defaults do |defaults|

      defaults[:required] = input.required
      if !form.new? && !input.valid?
        defaults["data-invalid"] = true
        input.validity_state.each do |constraint,violated|
          if violated
            defaults["data-#{constraint}"] = true
          end
        end
      end
    end

    value = input.value

    @options = options.map {  |object|
      Option.new(object:,
                 value_attribute:,
                 text_attribute: option_text_attribute)
    }

    @blank_option = BlankOption.from_param(include_blank)

    if value.nil? || value.to_s.strip == ""
      @selected_value = nil # explicitly nothing is selected
    else
      option = @options.detect { |option|
        value == option.value
      }
      if option.nil?
        if @blank_option && value == @blank_option.value
          @selected_value = @blank_option.value
        else
          raise SelectedValueNotFound.new(value:, value_attribute:, options:)
        end
      else
        @selected_value = option.value
      end
    end
  end

  def view_template
    select(**@html_attributes) {
      if @blank_option
        option(**@blank_option.option_attributes) {
          @blank_option.text
        }
      end
      @options.each do |option|
        option(
          **option.option_attributes,
          selected: option.value == @selected_value
        ) {
          option.text
        }
      end
    }
  end
private

  # @!visibility private
  class Option
    attr_reader :value, :text
    def initialize(object:,value_attribute:,text_attribute:)
      @value = object.send(value_attribute).then { |raw_value|
        RichString.new(raw_value).to_s_or_nil
      }
      @text = object.send(text_attribute).to_s
    end
    def option_attributes
      if self.value
        {
          value: self.value,
        }
      else 
        {}
      end
    end
  end

  # @!visibility private
  class BlankOption < Option
    def self.from_param(include_blank)
      if !include_blank
        return nil
      else
        self.new(include_blank)
      end
    end
    def initialize(include_blank)
      if include_blank == true
        @text = ""
        @value = nil
      elsif include_blank.kind_of?(Hash)
        if include_blank.key?(:value) && include_blank.key?(:text_content)
          @text = include_blank[:text_content]
          @value = include_blank[:value].nil? ? nil : include_blank[:value].to_s
        else
          raise ArgumentError, "when include_blank: is a Hash, it must include both :value and :text_content as keys. Got: #{include_blank.keys.join(", ")}"
        end
      else
        raise ArgumentError,"include_blank: was a #{include_blank.class}. It should be true, false, nil, or a Hash"
      end
    end

  end

  # @!visibility private
  class SelectedValueNotFound < ArgumentError
    def initialize(value:, value_attribute:, options:)
      options_found = options.map {
        v = it.send(value_attribute)
        [ v, v.class.name ].join("/")
      }
      super("selected_value #{value}/#{value.class} was not the value for #{value_attribute} on any of the options: #{options_found.join(", ")}")
    end
  end
end

