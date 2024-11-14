require "rexml"
module Brut::FrontEnd::Components

  module Inputs
    autoload(:TextField,"brut/front_end/components/inputs/text_field")
    autoload(:Select,"brut/front_end/components/inputs/select")
    autoload(:Textarea,"brut/front_end/components/inputs/textarea")
    autoload(:CsrfToken,"brut/front_end/components/inputs/csrf_token")
  end

  class Input < Brut::FrontEnd::Component
  end
end
