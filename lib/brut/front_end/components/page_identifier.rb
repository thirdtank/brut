# Renders a `<meta>` tag that contains the name of the page.  This is useful for end to end tests to assert that they are on a specific page before continuing with the test.  It can eliminate a lot of confusion when a test fails.
class Brut::FrontEnd::Components::PageIdentifier < Brut::FrontEnd::Component
  def initialize(page_name)
    @page_name = page_name
  end

  def view_template
    if Brut.container.project_env.production?
      return nil
    end
    meta(name: "class", content: @page_name)
  end
end
