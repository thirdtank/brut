# Used in development to handle a defined route but a missing page. This arranges to render a nicer error page than the default.
class Brut::FrontEnd::Handlers::MissingHandler < Brut::FrontEnd::Handler
  def initialize(route:)
    @route = route
  end
  def handle
    Brut::FrontEnd::Pages::MissingPage.new(route: @route)
  end

  class Form < Brut::FrontEnd::Form
  end
end
