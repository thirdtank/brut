# Creates a button tag to be used inside a form. This is only 
# needed if your form declared a `button` and you wish the value
# to be included whern the form is submitted (for example, if you have
# more than one submit button and wish to know which one was clicked on the
# back end).
class Brut::FrontEnd::Components::Inputs::ButtonTag < Brut::FrontEnd::Components::Input

  # Creates the appropriate button for the given {Brut::FrontEnd::Form} and input name. Note that if the
  # form has no value for this input, the value `"true"` will be used, as this allows you to create
  # buttons without worrying about an often irrelevant value.
  #
  # @param [Brut::FrontEnd::Form} form The form that is being rendered. This method will consult this class to understand the requirements on this input so its HTML is generated correctly.
  # @param [String] input_name the name of the input, which should be a member of `form`
  # @param [Integer] index if this input is part of an array, this is the index into that array. This is used to get the input's value.
  # @param [Hash] html_attributes any additional HTML attributes to include on the `<input>` element. Note 
  #               that if you set `type` here to be `reset` or `button`, this button will not submit
  #               the form (as per the HTML spec).  Also note that the various
  #               `form*` attributes *will* take effect and work as desired.
  def initialize(form:, input_name:, index: nil, **html_attributes)
    input = form_input(form:, input_name:, index:, 
                       clazz: Brut::FrontEnd::Forms::Button)

    @html_attributes = Brut::FrontEnd::Forms::HtmlAttributes.new(
      input:,
      initial_attributes: html_attributes
    ).with_defaults do |defaults|
      value = RichString.from_string(input.value)
      defaults[:value] = (value || "true").to_s
    end
  end

  def view_template
    button(**@html_attributes) do
      yield
    end
  end
end
