module Brut::FrontEnd::Components

  # Holds components designed to render HTML `<input>` and other form components.
  module Inputs
    autoload(:InputTag,"brut/front_end/components/inputs/input_tag")
    autoload(:ButtonTag,"brut/front_end/components/inputs/button_tag")
    autoload(:RadioButton,"brut/front_end/components/inputs/radio_button")
    autoload(:SelectTagWithOptions,"brut/front_end/components/inputs/select_tag_with_options")
    autoload(:TextareaTag,"brut/front_end/components/inputs/textarea_tag")
    autoload(:CsrfToken,"brut/front_end/components/inputs/csrf_token")
    autoload(:InvalidInputClassForFormInput,"brut/front_end/components/inputs/invalid_input_class_for_form_input")
  end

  # Base class for all inputs
  class Input < Brut::FrontEnd::Component

  private

    def form_input(form:, input_name:, index:, clazz:)
      input = form.input(input_name, index:)

      if input.class.name != clazz.name
        raise Brut::FrontEnd::Components::Inputs::InvalidInputClassForFormInput.new(
          component: self,
          required_class: clazz,
          received_class: input.class
        )
      end

      input
    end
  end
end
