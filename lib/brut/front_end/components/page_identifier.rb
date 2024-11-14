require "rexml"
class Brut::FrontEnd::Components::PageIdentifier < Brut::FrontEnd::Component
  def initialize(page_name)
    @page_name = page_name
  end

  def render
    if Brut.container.project_env.production?
      return ""
    end
    html_tag(:meta, name: "class", content: @page_name)
  end
end
