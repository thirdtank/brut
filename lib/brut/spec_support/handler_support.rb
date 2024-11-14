require_relative "flash_support"
require_relative "session_support"
module Brut::SpecSupport::HandlerSupport
  include Brut::SpecSupport::FlashSupport
  include Brut::SpecSupport::SessionSupport
end

