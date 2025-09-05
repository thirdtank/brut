# Creates a button tag to be used inside a form. This is only 
# needed if your form declared a `button` and you wish the value
# to be included whern the form is submitted (for example, if you have
# more than one submit button and wish to know which one was clicked on the
# back end).
class Brut::FrontEnd::Components::Inputs::ButtonTag < Brut::FrontEnd::Components::Input

  # Creates the appropriate button for the given {Brut::FrontEnd::Form} and input name.
  #
  # @param [Brut::FrontEnd::Form} form The form that is being rendered. This method will consult this class to understand the requirements on this input so its HTML is generated correctly.
  # @param [String] input_name the name of the input, which should be a member of `form`
  # @param [Integer] index if this input is part of an array, this is the index into that array. This is used to get the input's value.
  # @param [Hash] html_attributes any additional HTML attributes to include on the `<input>` element. Note 
  #               that if you set `type` here to be `reset` or `button`, this button will not submit
  #               the form (as per the HTML spec).  Also note that the various
  #               `form*` attributes *will* take effect and work as desired.
  def initialize(form:, input_name:, index: nil, **html_attributes)
    input = form.input(input_name, index:)
    if input.class.name != "Brut::FrontEnd::Forms::Button"
      raise ArgumentError, "#{self.class} can only be used with `button` elements, not #{input.class.name} form elements"
    end
    default_html_attributes = {}
    html_attributes = html_attributes.map { |key,value| [ key.to_sym, value ] }.to_h

    default_html_attributes[:name] = if input.array?
                                       "#{input.name}[]"
                                     else
                                       input.name
                                     end
    default_html_attributes[:value] = input.value

    @attributes = default_html_attributes.merge(html_attributes)
  end

  def view_template
    button(**@attributes) do
      yield
    end
  end
end
