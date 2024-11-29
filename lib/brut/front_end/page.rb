# A page is a component that has a layout and thus is intended to be
# an entire web page, not just a fragment.
class Brut::FrontEnd::Page < Brut::FrontEnd::Component
  include Brut::FrontEnd::HandlingResults
  using Brut::FrontEnd::Templates::HTMLSafeString::Refinement

  def layout = "default"

  def before_render = nil

  def handle!
    case before_render
    in URI => uri
      uri
    in Brut::FrontEnd::HttpStatus => http_status
      http_status
    else
      render
    end
  end

  # Overrides component's render to add the concept of a layout.
  # A layout is an HTML/ERB file that will contain this page's contents.
  def render
    Brut.container.layout_locator.locate(self.layout).
      then { |layout_erb_file| Brut::FrontEnd::Template.new(layout_erb_file)
      } => layout_template

    Brut.container.page_locator.locate(self.template_name).
      then { |erb_file| Brut::FrontEnd::Template.new(erb_file)
      } => template

    layout_template.render_template(self) do
      template.render_template(self).html_safe!
    end
  end

  def self.page_name = self.name
  def page_name = self.class.page_name
  def component_name = raise Brut::Framework::Errors::Bug,"#{self.class} is not a component"

private

  def template_name = RichString.new(self.class.name).underscorized.to_s.gsub(/^pages\//,"")

end

module Brut::FrontEnd::Pages
  autoload(:MissingPage,"brut/front_end/pages/missing_page.rb")
end
