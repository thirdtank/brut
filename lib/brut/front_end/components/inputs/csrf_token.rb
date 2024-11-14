class Brut::FrontEnd::Components::Inputs::CsrfToken < Brut::FrontEnd::Components::Input
  def initialize(csrf_token:)
    @csrf_token = csrf_token
  end
  def render
    html_tag(:input, type: "hidden", name: "authenticity_token", value: @csrf_token)
  end
end
