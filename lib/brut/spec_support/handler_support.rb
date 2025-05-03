require_relative "flash_support"
require_relative "clock_support"
require_relative "session_support"

# Convienience methods for testing handlers.  When testing handlers, the following matchers may be useful:
#
#
# * `have_redirected_to` to check that the handler redirected to a give URI
# * `have_rendered` to check that the handler rendered a specific page
# * `have_returned_http_status` to check that the handler returned an HTTP status
module Brut::SpecSupport::HandlerSupport
  include Brut::SpecSupport::FlashSupport
  include Brut::SpecSupport::ClockSupport
  include Brut::SpecSupport::SessionSupport
end

