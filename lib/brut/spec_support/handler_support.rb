require_relative "flash_support"
require_relative "clock_support"
require_relative "session_support"
module Brut::SpecSupport::HandlerSupport
  include Brut::SpecSupport::FlashSupport
  include Brut::SpecSupport::ClockSupport
  include Brut::SpecSupport::SessionSupport
end

