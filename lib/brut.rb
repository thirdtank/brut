require_relative "brut/framework"

# Brut is a way to make web apps with Ruby. It focuses on web standards, object-orientation, and other
# fundamentals. Brut seeks to minimize abstractions where possible.
#
# Brut encourages the use of the browser's technology and encourages you to build a web app based
# on good practices that are set up by default.  Brut may not look easy, but it aims to be simple.
# It attempts to minimize dependencies and complexity, while leveraging
# common tested Ruby libraries related to web development.
#
# Have fun!
module Brut
  autoload(:FrontEnd, "brut/front_end")
  autoload(:BackEnd, "brut/back_end")
  autoload(:I18n, "brut/i18n")
  autoload(:Instrumentation,"brut/instrumentation")
  autoload(:SinatraHelpers, "brut/sinatra_helpers")
  # DO NOT autoload(:CLI) - that is intended to be require-able on its own
end
require "sequel/plugins"
