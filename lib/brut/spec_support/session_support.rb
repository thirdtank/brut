# Convienience methods for creating sessions inside a test.
module Brut::SpecSupport::SessionSupport
  # Create an empty session, using the class configured by the app
  def empty_session = Brut.container.session_class.new(rack_session: {})
end
