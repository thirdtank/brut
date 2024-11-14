class Brut::FrontEnd::Components::Inputs::Textarea < Brut::FrontEnd::Components::Input
  def self.for_form_input(form:, input_name:, html_attributes: {})
    default_html_attributes = {}
    input = form[input_name]
    default_html_attributes["required"] = input.required
    default_html_attributes["name"]     = input.name
    if input.maxlength
      default_html_attributes["maxlength"] = input.maxlength
    end
    if input.minlength
      default_html_attributes["minlength"] = input.minlength
    end
    if !form.new? && !input.valid?
      default_html_attributes["data-invalid"] = true
      input.validity_state.each do |constraint,violated|
        if violated
          default_html_attributes["data-#{constraint}"] = true
        end
      end
    end
    Brut::FrontEnd::Components::Inputs::Textarea.new(default_html_attributes.merge(html_attributes), input.value)
  end
  def initialize(attributes, value)
    @sanitized_attributes = attributes.map { |key,value|
        [
          key.to_s.gsub(/[\s\"\'>\/=]/,"-"),
          value
        ]
    }.select { |key,value|
      !value.nil?
    }.to_h
    @value = value
  end

  def sanitized_attributes = @sanitized_attributes

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
    %{
      <textarea #{attribute_string}>#{ @value }</textarea>
    }
  end
end
