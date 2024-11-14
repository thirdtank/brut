class Brut::FrontEnd::Components::Inputs::TextField < Brut::FrontEnd::Components::Input
  def self.for_form_input(form:, input_name:, html_attributes: {})
    default_html_attributes = {}
    input = form[input_name]
    default_html_attributes["required"] = input.required
    default_html_attributes["pattern"]  = input.pattern
    default_html_attributes["type"]     = input.type
    default_html_attributes["name"]     = input.name
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
    if input.type == "checkbox"
      default_html_attributes["value"] = "true"
      default_html_attributes["checked"] = input.value == "true"
    else
      default_html_attributes["value"] = input.value
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
