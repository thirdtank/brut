# Generates an HTML `<textarea>` field based on a form input.
class Brut::FrontEnd::Components::Inputs::TextareaTag < Brut::FrontEnd::Components::Input

  # Creates the appropriate textarea for the given {Brut::FrontEnd::Form} and input name.
  #
  # @param [Brut::FrontEnd::Form} form The form that is being rendered. This method will consult this class to understand the requirements on this textarea so its HTML is generated correctly.
  # @param [String] input_name the name of the input, which should be a member of `form`
  # @param [Integer] index if this input is part of an array, this is the index into that array. This is used to get the input's value.
  # @param [Hash] html_attributes any additional HTML attributes to include on the `<textarea>` element.
  def initialize(form:, input_name:, index: nil, **html_attributes)
    input = form_input(form:, input_name:, index:, 
                       clazz: Brut::FrontEnd::Forms::Input)

    @html_attributes = Brut::FrontEnd::Forms::HtmlAttributes.new(
      input:,
      initial_attributes: html_attributes
    ).with_defaults do |defaults|

      defaults[:required] = input.required
      if input.maxlength
        defaults[:maxlength] = input.maxlength
      end
      if input.minlength
        defaults[:minlength] = input.minlength
      end
      if !form.new? && !input.valid?
        defaults["data-invalid"] = true
        input.validity_state.each do |constraint,violated|
          if violated
            defaults["data-#{constraint}"] = true
          end
        end
      end
    end
    @value = input.value
  end

  def invalid? = @html_attributes["data-invalid"] == true

  def view_template
    textarea(**@html_attributes) {
      @value
    }
  end
end
