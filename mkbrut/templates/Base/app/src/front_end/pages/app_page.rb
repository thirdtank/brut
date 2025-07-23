# Base class for all pages in the app
# Note that while Brut::FrontEnd::Page is a subclass
# of Brut::FrontEnd::Component, that is not the case
# for your app's pages and components.  Thus, there is a small amount
# of duplication here.
class AppPage < Brut::FrontEnd::Page
  include Brut::Framework::Errors    # See AppComponent
  include CustomElementRegistration  # See AppComponent
  include Brut::FrontEnd::Components # See AppComponent
end

