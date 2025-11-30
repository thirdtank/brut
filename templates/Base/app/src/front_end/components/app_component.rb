# Base class for your app's components.
class AppComponent < Brut::FrontEnd::Component
  include Brut::Framework::Errors    # provides access to methods in this module
  include Brut::FrontEnd::Components # Allows Brut-provided components to be
                                     # used as a Phlex "kit"
  include CustomElementRegistration
end

