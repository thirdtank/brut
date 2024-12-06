# Used in development to handle a defined route but a missing page. This arranges to render a nicer error page than the default.
class Brut::FrontEnd::Handlers::MissingHandler < Brut::FrontEnd::Handler
  def handle(route:)
    Brut::FrontEnd::Pages::MissingPage.new(route:)
  end

  class Form < Brut::FrontEnd::Form
  end
end
