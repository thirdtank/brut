# Renders the custom elements used to manage both client- and server-side constraint violations via the `<brut-cv-messages>` and `<brut-cv>` tags. Each constraint violation on the input's {Brut::FrontEnd::Forms::ValidityState} will generate a `<brut-cv server-generated>` tag that will contain the I18n translation of the violation's {Brut::FrontEnd::Forms::ConstraintViolation#key} prefixed with `"cv.cs"` or `"cv.ss"`.
#
# The general form of this component will be:
#
# ```html
# <brut-cv-messages input-name="«input_name»">
#   <brut-cv server-generated client-side>
#     «message»
#   </brut-cv>
#   <brut-cv server-generated server-side>
#     «message»
#   </brut-cv>
#   <!- ... ->
# </brut-cv-messages>
# ```
#
# Notes:
#
# * If the form is considered #{Brut::FrontEnd::Form#new?}, then the client-side constraint violations
#   will not be generated.  This is to prevent a fresh form from being generated with a bunch of 
#   errors already present.
# * If using `<brut-form>`, the `<brut-cv-messages>` element this generates will be where it inserts
#   client side constraint violations.
class Brut::FrontEnd::Components::ConstraintViolations < Brut::FrontEnd::Component
  # Create a new ConstraintViolations component
  #
  # @param [Brut::FrontEnd::Form] form the form in which this component is being rendered.
  # @param [String|Symbol] input_name the name of the input, based on what was used in the form object.
  # @param [Hash] html_attributes attributes to be placed on the outer `<brut-cv-messages>` element.
  # @param [Integer] index index of the input, for array-based inputs
  # @param [Hash] message_html_attributes attributes to be placed on each inner `<brut-cv>` element.
  def initialize(form:, input_name:, index: nil, message_html_attributes: {}, **html_attributes)
    @form                    =  form
    @input_name              =  input_name
    @array                   = !index.nil?
    @index                   =  index || 0
    @html_attributes         =  html_attributes.map {|name,value| [ name.to_sym, value ] }.to_h
    @message_html_attributes =  message_html_attributes.map {|name,value| [ name.to_sym, value ] }.to_h
  end

  def view_template
    html_attributes = {
      "input-name": @array ? "#{@input_name}[]" : @input_name.to_s,
    }.merge(@html_attributes)

    message_html_attributes = {
      "server-generated": true,
    }.merge(@message_html_attributes)

    brut_cv_messages(**html_attributes) do
      @form.input(@input_name, index: @index).validity_state.each do |constraint|
        if constraint.client_side?
          if !@form.new?
            brut_cv(**message_html_attributes, client_side: true) do
              t("cv.cs.#{constraint}", **constraint.context)
            end
          end
        else
          brut_cv(**message_html_attributes, server_side: true) do
            t("cv.ss.#{constraint}", **constraint.context)
          end
        end
      end
    end
  end

end
