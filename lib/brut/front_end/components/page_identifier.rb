# Renders a `<meta>` tag (in dev and test) that contains the name of the page.  This is useful for end to end tests to assert that they are on a specific page before continuing with the test.  It can eliminate a lot of confusion when a test fails.
class Brut::FrontEnd::Components::PageIdentifier < Brut::FrontEnd::Component
  # Create the component
  #
  # @param [Brut::FrontEnd::Page] page the current page
  def initialize(page)
    @page = page
  end

  def view_template
    if Brut.container.project_env.production?
      return nil
    end
    meta(name: "class", content: @page.page_name)
  end
end
