# Renders an HTML `<input type="radio">`. Unlike other form fields, radio
# button groups require several HTML elements to present the visitor a choice.  All of the classes
# internal to the {Brut::FrontEnd::Form} treat the radio button group as a single input with
# a single name and value.  When it comes time to generate HTML, this class is used
# to generate a single radio button from a group.
class Brut::FrontEnd::Components::Inputs::RadioButton < Brut::FrontEnd::Components::Inputs::InputTag
  # Creates a radio button that is part of a radio button group.  You should call this
  # method once for each radio button in the group.
  #
  # @param [Brut::FrontEnd::Form} form The form that is being rendered. This method will consult this class to understand the requirements on this input so its HTML is generated correctly.
  # @param [String] input_name the name of the input, which should be a member of `form`
  # @param [String] value the value for this radio button.  The {Brut::FrontEnd::Forms::RadioButtonGroupInput} value is compared
  # against this value to determine if this `<input>` will have the `checked` attribute.
  # @param [Hash] html_attributes any additional HTML attributes to include on the `<input>` element.
  def self.for_form_input(form:, input_name:, value:, html_attributes: {})
    default_html_attributes = {}
    html_attributes = html_attributes.map { |key,value| [ key.to_sym, value ] }.to_h
    input = form.input(input_name)

    default_html_attributes[:required] = input.required
    default_html_attributes[:type]     = "radio"
    default_html_attributes[:name]     = input.name
    default_html_attributes[:value]    = value

    selected_value = input.value

    if selected_value == value
      default_html_attributes[:checked] = true
    end

    if !form.new? && !input.valid?
      default_html_attributes["data-invalid"] = true
      input.validity_state.each do |constraint,violated|
        if violated
          default_html_attributes["data-#{constraint}"] = true
        end
      end
    end
    Brut::FrontEnd::Components::Inputs::RadioButton.new(default_html_attributes.merge(html_attributes))
  end
end
