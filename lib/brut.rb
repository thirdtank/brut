require_relative "brut/framework"

# Convention is as follows:
#
# * singluar thing is a class, the base class of others  being used, e.g. the base page is called Brut::Page
#   (e.g. and not Brut::Pages::Base).
module Brut
  module FrontEnd
    autoload(:AssetMetadata, "brut/front_end/asset_metadata")
    autoload(:Component, "brut/front_end/component")
    autoload(:Components, "brut/front_end/component")
    autoload(:Download, "brut/front_end/download")
    autoload(:Flash, "brut/front_end/flash")
    autoload(:Form, "brut/front_end/form")
    autoload(:Handler, "brut/front_end/handler")
    autoload(:Handlers, "brut/front_end/handler")
    autoload(:HandlingResults, "brut/front_end/handling_results")
    autoload(:HttpMethod, "brut/front_end/http_method")
    autoload(:HttpStatus, "brut/front_end/http_status")
    autoload(:Middleware, "brut/front_end/middleware")
    autoload(:Middlewares, "brut/front_end/middleware")
    autoload(:Page, "brut/front_end/page")
    autoload(:Pages, "brut/front_end/page")
    autoload(:RequestContext, "brut/front_end/request_context")
    autoload(:RouteHook, "brut/front_end/route_hook")
    autoload(:RouteHooks, "brut/front_end/route_hook")
    autoload(:Routing, "brut/front_end/routing")
    autoload(:Session, "brut/front_end/session")
  end
  module BackEnd
    autoload(:Result, "brut/back_end/result")
    autoload(:Validators, "brut/back_end/validator")
  end
  # DO NOT autoload(:CLI) - that is intended to be require-able on its own
  autoload(:I18n, "brut/i18n")
  autoload(:Instrumentation,"brut/instrumentation")
  autoload(:SinatraHelpers, "brut/sinatra_helpers")
end
require "sequel/plugins"
