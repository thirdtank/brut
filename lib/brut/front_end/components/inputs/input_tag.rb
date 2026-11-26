# Generates an HTML `<input>` field based on a form input.
class Brut::FrontEnd::Components::Inputs::InputTag < Brut::FrontEnd::Components::Input

  # Creates the appropriate input for the given {Brut::FrontEnd::Form} and input name.
  #
  # @param [Brut::FrontEnd::Form] form The form that is being rendered. This method will consult this class to understand the requirements on this input so its HTML is generated correctly.
  # @param [String] input_name the name of the input, which should be a member of `form`
  # @param [Integer] index if this input is part of an array, this is the index into that array. This is used to get the input's value.
  # @param [Hash] html_attributes any additional HTML attributes to include on the `<input>` element.
  def initialize(form:, input_name:, index: nil, **html_attributes)
    input = form_input(form:, input_name:, index:, 
                       clazz: Brut::FrontEnd::Forms::Input)
    @html_attributes = Brut::FrontEnd::Forms::HtmlAttributes.new(
      input:,
      initial_attributes: html_attributes
    ).with_defaults do |defaults|

      defaults[:required] = input.required
      defaults[:pattern]  = input.pattern
      defaults[:type]     = input.type

      if input.max
        defaults[:max] = input.max
      end
      if input.maxlength
        defaults[:maxlength] = input.maxlength
      end
      if input.min
        defaults[:min] = input.min
      end
      if input.minlength
        defaults[:minlength] = input.minlength
      end
      if input.step
        defaults[:step] = input.step
      end

      if input.type == "checkbox"
        defaults[:value] = input.array? ? index.to_s : "true"
        defaults[:checked] = input.value == "true"
      else
        defaults[:value] = input.value
      end
      if !form.new? && !input.valid?
        defaults["aria-invalid"] = "true"
        defaults["aria-errormessage"] = SecureRandom.uuid # XXX
      end
    end
  end

  def view_template
    input(**@html_attributes)
  end
end
