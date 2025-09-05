# Generates an HTML `<input>` field based on a form input.
class Brut::FrontEnd::Components::Inputs::InputTag < Brut::FrontEnd::Components::Input
  def invalid? = @attributes["data-invalid"] == true

  # Creates the appropriate input for the given {Brut::FrontEnd::Form} and input name.
  #
  # @param [Brut::FrontEnd::Form} form The form that is being rendered. This method will consult this class to understand the requirements on this input so its HTML is generated correctly.
  # @param [String] input_name the name of the input, which should be a member of `form`
  # @param [Integer] index if this input is part of an array, this is the index into that array. This is used to get the input's value.
  # @param [Hash] html_attributes any additional HTML attributes to include on the `<input>` element.
  def initialize(form:, input_name:, index: nil, **html_attributes)
    input = form.input(input_name, index:)
    if input.class.name != "Brut::FrontEnd::Forms::Input"
      raise ArgumentError, "#{self.class} can only be used with `input` elements, not #{input.class.name} form elements"
    end
    default_html_attributes = {}
    html_attributes = html_attributes.map { |key,value| [ key.to_sym, value ] }.to_h

    default_html_attributes[:required] = input.required
    default_html_attributes[:pattern]  = input.pattern
    default_html_attributes[:type]     = input.type
    default_html_attributes[:name]     = if input.array?
                                            "#{input.name}[]"
                                          else
                                            input.name
                                          end

    if input.max
      default_html_attributes[:max] = input.max
    end
    if input.maxlength
      default_html_attributes[:maxlength] = input.maxlength
    end
    if input.min
      default_html_attributes[:min] = input.min
    end
    if input.minlength
      default_html_attributes[:minlength] = input.minlength end
    if input.step
      default_html_attributes[:step] = input.step
    end
    value = input.value

    if input.type == "checkbox"
      default_html_attributes[:value] = (index || true).to_s
      default_html_attributes[:checked] = value == "true"
    else
      default_html_attributes[:value] = value.nil? ? nil : value.to_s
    end
    if !form.new? && !input.valid?
      default_html_attributes["data-invalid"] = true
      input.validity_state.each do |constraint|
        default_html_attributes["data-#{constraint}"] = true
      end
    end
    @attributes = default_html_attributes.merge(html_attributes)
  end

  def view_template
    input(**@attributes)
  end
end
