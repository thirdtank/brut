# Renders a hidden field for a form that contains the current CSRF token. You only need
# to use this directly if you are building a form without {Brut::FrontEnd::Components::FormTag}
class Brut::FrontEnd::Components::Inputs::CsrfToken < Brut::FrontEnd::Components::Input
  def initialize(csrf_token:)
    @csrf_token = csrf_token
  end
  def view_template
    input(type: "hidden", name: "authenticity_token", value: @csrf_token)
  end
end
