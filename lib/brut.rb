require_relative "brut/framework"

# Brut is a way to make web apps with Ruby. It focuses on web standards, object-orientation, and other fundamentals. Brut seeks to
# minimize abstractions where possible.
#
# Brut encourages the use of the browser's technology and encourages you to build a web app based on good practices that are set up by
# default.  Brut may not look easy, but it aims to be simple.  It attempts to minimize dependencies and complexity, while leveraging
# common tested Ruby libraries related to web development.
#
# Have fun!
module Brut
  autoload(:FrontEnd, "brut/front_end")
  # The _back end_ of a Brut app is where your app's business logic and database are managed.  While the bulk of your Brut app's code
  # will be in the back end, Brut is far less prescriptive about how to manage that than it is the front end.
  module BackEnd
    autoload(:Validators, "brut/back_end/validator")
    autoload(:Sidekiq, "brut/back_end/sidekiq")
    # Do not put SeedData here - it must be loaded only when needed
  end
  # I18n is where internationalization and localization support lives.
  autoload(:I18n, "brut/i18n")
  autoload(:Instrumentation,"brut/instrumentation")
  autoload(:SinatraHelpers, "brut/sinatra_helpers")
  # DO NOT autoload(:CLI) - that is intended to be require-able on its own
end
require "sequel/plugins"
