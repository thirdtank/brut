module Brut::FrontEnd::Components

  # Holds components designed to render HTML `<input>` and other form components.
  module Inputs
    autoload(:InputTag,"brut/front_end/components/inputs/input_tag")
    autoload(:ButtonTag,"brut/front_end/components/inputs/button_tag")
    autoload(:RadioButton,"brut/front_end/components/inputs/radio_button")
    autoload(:SelectTagWithOptions,"brut/front_end/components/inputs/select_tag_with_options")
    autoload(:TextareaTag,"brut/front_end/components/inputs/textarea_tag")
    autoload(:CsrfToken,"brut/front_end/components/inputs/csrf_token")
  end

  # Base class for all inputs
  class Input < Brut::FrontEnd::Component
  end
end
