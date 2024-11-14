module Brut::SpecSupport::SessionSupport
  def empty_session = Brut.container.session_class.new(rack_session: {})
end
