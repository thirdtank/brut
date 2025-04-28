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
module Brut::FrontEnd
  autoload(:AssetMetadata, "brut/front_end/asset_metadata")
  autoload(:AssetPathResolver, "brut/front_end/asset_path_resolver")
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
  autoload(:InlineSvgLocator, "brut/front_end/inline_svg_locator")
  autoload(:GenericResponse, "brut/front_end/generic_response")
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
