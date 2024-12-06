# Generates an HTML `<textarea>` field.
class Brut::FrontEnd::Components::Inputs::Textarea < Brut::FrontEnd::Components::Input
  # Creates the appropriate textarea for the given {Brut::FrontEnd::Form} and input name.
  # Generally, you want to use this method over the initializer.
  #
  # @param [Brut::FrontEnd::Form} form The form that is being rendered. This method will consult this class to understand the requirements on this textarea so its HTML is generated correctly.
  # @param [String] input_name the name of the input, which should be a member of `form`
  # @param [Hash] html_attributes any additional HTML attributes to include on the `<textarea>` element.
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
  # Create an instance
  #
  # @param [Hash] attributes HTML attributes to put on the element.
  # @param [String] value the value to place inside the text area
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
