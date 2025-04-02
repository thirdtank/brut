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
  # In Brut, the _front end_ is considered anything that interacts directly with a web browser or HTTP.  This includes rendering HTML,
  # managing JavaScript and CSS, and processing form submissions.  It contrasts to {Brut::BackEnd}, which handles the business logic
  # and database.
  #
  # You {Brut::App} defines pages, forms, and actions. A page is backed by a subclass of {Brut::FrontEnd::Page}, which provides
  # dynamic data for rendering. A page can reference {Brut::FrontEnd::Component} subclasses to allow functional decomposition of front
  # end logic and markup, as well as re-use.  Both pages and components have ERB files that describe the HTML to be rendered.
  #
  # A {Brut::FrontEnd::Form} subclass defines a form that a browser will submit to your app. That
  # submission is processed by a {Brut::FrontEnd::Handler} subclass.  Handlers can also respond to other HTTP requests.
  #
  # In addition to responding to requests, you can subclass {Brut::FrontEnd::RouteHook} or {Brut::FrontEnd::Middleware} to perform
  # further manipulation of the request.
  #
  # The entire front-end is based on Rack, so you should be able to achieve anything you need to.
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
