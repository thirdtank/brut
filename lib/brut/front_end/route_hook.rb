module Brut::FrontEnd
  # Base class for all route hooks. A route hook must implement either `before` or `after` and can be used via
  # {Brut::Framework::App.before} or {Brut::Framework::App.after}.
  #
  # A route hook differs from Middleware in to ways:
  #
  # * A route hook has a rich structured return type that is more expressive that Rack's array, however less powerful.
  # * A route hook can be injected with session and request information via {Brut::FrontEnd::RequestContext}.  This allows your route
  # hooks to easily access information like the currently-logged-in user, session, flash, or query string parameters.
  #
  # Note that while a route hook can be used as both a before and an after, state will not be shared.
  class RouteHook
    include Brut::FrontEnd::HandlingResults
    include Brut::Framework::Errors

    # Subclasses should implement this if they intend to be used as before hooks. The method parameters that the subclass uses will
    # determine what information is avaiable.
    #
    # The return type determines what happens:
    #
    # * `URI` - the browser will be redirected to this URI
    # * `Brut::FrontEnd::HttpStatus` - the request will be terminated with this status
    # * `false` - the request is terminated with a 500
    # * `true` or `nil` - the request will continue to the next hook or to the route handler. Use {#continue} if this is what you want to happen
    #
    # @return [URI|Brut::FrontEnd::HttpStatus|false|true|nil]
    def before
      abstract_method!
    end

    # Subclasses should implement this if they intend to be used as after hooks. The method parameters that the subclass uses will
    # determine what information is avaiable.
    #
    # The return type determines what happens:
    #
    # * `URI` - the browser will be redirected to this URI
    # * `Brut::FrontEnd::HttpStatus` - the request will be terminated with this status
    # * `false` - the request is terminated with a 500
    # * `true` or `nil` - the request will continue to the next hook or to the browser. Use {#continue} if this is what you want to happen
    #
    # @return [URI|Brut::FrontEnd::HttpStatus|false|true|nil]
    def after
      abstract_method!
    end

    # Return this to continue the hook. This is preferred over `true` or `nil` as it communicates the intent of what should happen
    def continue = true
  end

  module RouteHooks
    autoload(:LocaleDetection, "brut/front_end/route_hooks/locale_detection")
    autoload(:SetupRequestContext, "brut/front_end/route_hooks/setup_request_context")
    autoload(:AgeFlash, "brut/front_end/route_hooks/age_flash")
    autoload(:CSPNoInlineStylesOrScripts,"brut/front_end/route_hooks/csp_no_inline_styles_or_scripts")
    autoload(:CSPNoInlineScripts,"brut/front_end/route_hooks/csp_no_inline_scripts")
  end
end
