# Generates an HTML `<input>` field.
class Brut::FrontEnd::Components::Inputs::TextField < Brut::FrontEnd::Components::Input
  # Creates the appropriate input for the given {Brut::FrontEnd::Form} and input name.
  # Generally, you want to use this method over the initializer.
  #
  # @param [Brut::FrontEnd::Form} form The form that is being rendered. This method will consult this class to understand the requirements on this input so its HTML is generated correctly.
  # @param [String] input_name the name of the input, which should be a member of `form`
  # @param [Integer] index if this input is part of an array, this is the index into that array. This is used to get the input's value.
  # @param [Hash] html_attributes any additional HTML attributes to include on the `<input>` element.
  def self.for_form_input(form:, input_name:, index: nil, html_attributes: {})
    default_html_attributes = {}
    html_attributes = html_attributes.map { |key,value| [ key.to_s, value ] }.to_h
    index ||= 0
    input = form.input(input_name, index:)

    default_html_attributes["required"] = input.required
    default_html_attributes["pattern"]  = input.pattern
    default_html_attributes["type"]     = input.type
    default_html_attributes["name"]     = if input.array?
                                            "#{input.name}[]"
                                          else
                                            input.name
                                          end

    if input.max
      default_html_attributes["max"] = input.max
    end
    if input.maxlength
      default_html_attributes["maxlength"] = input.maxlength
    end
    if input.min
      default_html_attributes["min"] = input.min
    end
    if input.minlength
      default_html_attributes["minlength"] = input.minlength
    end
    if input.step
      default_html_attributes["step"] = input.step
    end
    value = input.value

    if input.type == "checkbox"
      default_html_attributes["value"] = "true"
      default_html_attributes["checked"] = value == "true"
    else
      default_html_attributes["value"] = value
    end
    if !form.new? && !input.valid?
      default_html_attributes["data-invalid"] = true
      input.validity_state.each do |constraint,violated|
        if violated
          default_html_attributes["data-#{constraint}"] = true
        end
      end
    end
    Brut::FrontEnd::Components::Inputs::TextField.new(default_html_attributes.merge(html_attributes))
  end

  # Create an instance
  #
  # @param [Hash] attributes HTML attributes to put on the element.
  def initialize(attributes)
    @sanitized_attributes = attributes.map { |key,value|
        [
          key.to_s.gsub(/[\s\"\'>\/=]/,"-"),
          value
        ]
    }.select { |key,value|
      !value.nil?
    }.to_h
  end

  def render
    attribute_string = @sanitized_attributes.map { |key,value|
      if value == true
        key
      elsif value == false
        ""
      else
        REXML::Attribute.new(key,value).to_string
      end
    }.join(" ")
    "<input #{attribute_string}>"
  end
end
