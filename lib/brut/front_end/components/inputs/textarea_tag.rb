# Generates an HTML `<textarea>` field.
class Brut::FrontEnd::Components::Inputs::TextareaTag < Brut::FrontEnd::Components::Input
  # Creates the appropriate textarea for the given {Brut::FrontEnd::Form} and input name.
  # Generally, you want to use this method over the initializer.
  #
  # @param [Brut::FrontEnd::Form} form The form that is being rendered. This method will consult this class to understand the requirements on this textarea so its HTML is generated correctly.
  # @param [String] input_name the name of the input, which should be a member of `form`
  # @param [Integer] index if this input is part of an array, this is the index into that array. This is used to get the input's value.
  # @param [Hash] html_attributes any additional HTML attributes to include on the `<textarea>` element.
  def self.for_form_input(form:, input_name:, index: nil, html_attributes: {})
    html_attributes = html_attributes.map { |key,value| [ key.to_sym, value ] }.to_h
    default_html_attributes = {}

    index ||= 0
    input = form.input(input_name, index:)

    default_html_attributes[:required] = input.required
    default_html_attributes[:name]     = if input.array?
                                            "#{input.name}[]"
                                          else
                                            input.name
                                          end
    if input.maxlength
      default_html_attributes[:maxlength] = input.maxlength
    end
    if input.minlength
      default_html_attributes[:minlength] = input.minlength
    end
    if !form.new? && !input.valid?
      default_html_attributes["data-invalid"] = true
      input.validity_state.each do |constraint,violated|
        if violated
          default_html_attributes["data-#{constraint}"] = true
        end
      end
    end
    value = input.value
    Brut::FrontEnd::Components::Inputs::TextareaTag.new(default_html_attributes.merge(html_attributes), value)
  end

  def initialize(form:, input_name:, index: nil, **html_attributes)
    html_attributes = html_attributes.map { |key,value| [ key.to_sym, value ] }.to_h
    default_html_attributes = {}

    index ||= 0
    input = form.input(input_name, index:)

    default_html_attributes[:required] = input.required
    default_html_attributes[:name]     = if input.array?
                                            "#{input.name}[]"
                                          else
                                            input.name
                                          end
    if input.maxlength
      default_html_attributes[:maxlength] = input.maxlength
    end
    if input.minlength
      default_html_attributes[:minlength] = input.minlength
    end
    if !form.new? && !input.valid?
      default_html_attributes["data-invalid"] = true
      input.validity_state.each do |constraint,violated|
        if violated
          default_html_attributes["data-#{constraint}"] = true
        end
      end
    end
    @value = input.value
    @attributes = default_html_attributes.merge(html_attributes)
  end

  def invalid? = @attributes["data-invalid"] == true

  def view_template
    textarea(**@attributes) {
      @value
    }
  end
end
