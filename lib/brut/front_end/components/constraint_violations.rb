# Renders the custom elements used to manage both client- and server-side constraint violations via the `<brut-cv-messages>` and `<brut-cv>` tags. Each constraint violation on the input's {Brut::FrontEnd::Forms::ValidityState} will generate a `<brut-cv server-side>` tag that will contain the I18n translation of the violation's {Brut::FrontEnd::Forms::ConstraintViolation#key} prefixed with `"cv.be"`.
#
# The general form of this component will be:
#
# ```html
# <brut-cv-messages input-name="«input_name»">
#   <brut-cv server-side>
#     «message»
#   </brut-cv>
#   <brut-cv server-side>
#     «message»
#   </brut-cv>
#   <!- ... ->
# </brut-cv-messages>
# ```
#
# Note that if you are using `<brut-form>` then `<brut-cv>` elements will be inserted into the `<brut-cv-messages>` element, however
# they will not have the `server-side` attribute.
#
# You will most commonly use this component via {Brut::FrontEnd::Component::Helpers#constraint_violations}.
class Brut::FrontEnd::Components::ConstraintViolations < Brut::FrontEnd::Component
  # Create a new ConstraintViolations component
  #
  # @param [Brut::FrontEnd::Form] form the form in which this component is being rendered.
  # @param [String|Symbol] input_name the name of the input, based on what was used in the form object.
  # @param [Hash] html_attributes attributes to be placed on the outer `<brut-cv-messages>` element.
  # @param [Hash] message_html_attributes attributes to be placed on each inner `<brut-cv>` element.
  def initialize(form:, input_name:, message_html_attributes: {}, **html_attributes)
    @form                    = form
    @input_name              = input_name
    @html_attributes         = html_attributes
    @message_html_attributes = message_html_attributes
  end

  def render
    html_attributes = {
      "input-name": @input_name
    }.merge(@html_attributes)

    message_html_attributes = {
      "server-side": true,
    }.merge(@message_html_attributes)

    html_tag("brut-cv-messages", **html_attributes) do
      @form[@input_name].validity_state.select { |constraint|
        !constraint.client_side?
      }.map { |constraint|
        html_tag("brut-cv",**message_html_attributes) do
          t("cv.be.#{constraint}", **constraint.context).capitalize
        end
      }.join("\n")
    end
  end
end
