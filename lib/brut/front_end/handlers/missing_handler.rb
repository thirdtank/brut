class Brut::FrontEnd::Handlers::MissingHandler < Brut::FrontEnd::Handler
  def handle(route:)
    Brut::FrontEnd::Pages::MissingPage.new(route:)
  end

  class Form < Brut::FrontEnd::Form
  end
end
