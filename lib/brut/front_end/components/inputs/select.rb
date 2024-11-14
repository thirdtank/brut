class Brut::FrontEnd::Components::Inputs::Select < Brut::FrontEnd::Components::Input
  def self.for_form_input(form:,
                          input_name:,
                          options:,
                          selected_value:,
                          value_attribute:,
                          option_text_attribute:,
                          html_attributes: {})
    default_html_attributes = {}
    input = form[input_name]
    default_html_attributes["required"] = input.required
    if !form.new? && !input.valid?
      default_html_attributes["data-invalid"] = true
      input.validity_state.each do |constraint,violated|
        if violated
          default_html_attributes["data-#{constraint}"] = true
        end
      end
    end
    Brut::FrontEnd::Components::Inputs::Select.new(
      name: input.name,
      options:,
      selected_value:,
      value_attribute:,
      option_text_attribute:,
      html_attributes: default_html_attributes.merge(html_attributes)
    )
  end
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
