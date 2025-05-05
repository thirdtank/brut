module Brut::FrontEnd
  # A handler responds to all HTTP requests other than those that render a page.
  # Like a page, the handler is initialized with any of the data it needs.  The {#handle} method will
  # be called to perform whatever action is needed, and its return value will determine what
  # ther esponse will be.
  #
  # To create a handler, after defining a route or form,
  # subclass this class (or, more likely, your app's `AppHandler`) and
  # provide an initializer that accepts keyword arguments.  The names of these arguments will be used
  # to locate the values that Brut will pass in when creating your page object. If your handler
  # is for a form, be sure to include the `form:` keyword argument.
  #
  # Consult Brut's documentation on keyword injection to know what values you may use and how values are located.
  #
  # Then, implement {#handle} to perform whatever logic is needed to handle the request.
  #
  # You may also define `before_handle` which will be called before {#handle} to potentially abort
  # the request.  This is mostly useful if you have a base class for some of your handlers and want to
  # share cross-cutting logic.
  #
  # Note that the public API for handlers is {#handle!}, which is what you should call in a test.
  class Handler
    include Brut::FrontEnd::HandlingResults
    include Brut::Framework::Errors

    # You must implement this to accept whatever parameters you need. See {Brut::FrontEnd::RequestContext} for how that works.
    # The type of the return value determines what will happen:
    #
    # * Instance of `URI` - browser will redirect to this URI. Typically, you would do this by calling {Brut::FrontEnd::HandlingResults#redirect_to}.
    # * Instance of {Brut::FrontEnd::Component} (which notably includes {Brut::FrontEnd::Page}) - renders that component or page
    # * Array of two items, with the first being an Instance of {Brut::FrontEnd::Component} and the second being an {Brut::FrontEnd::HttpStatus} -  renders that component or page, but responds with the given HTTP status. Useful for Ajax requests that don't return 200, but do return useful content.
    # * Instance of {Brut::FrontEnd::HttpStatus} - returns just that status code. Typically you would do this by calling {Brut::FrontEnd::HandlingResults#http_status}
    # * Instance of {Brut::FrontEnd::Download} - sends a file download to the browser.
    # * Instance of {Brut::FrontEnd::GenericResponse} - sends itself as the rack response. Use this only if
    # you cannot use one of the other options
    #
    # @return [URI|Brut::FrontEnd::Component,Array,Brut::FrontEnd::HttpStatus,Brut::FrontEnd::Download]
    def handle(**)
      abstract_method!
    end

    # Override this to performa any checks before {#handle} is called.  This should
    # return `nil` if {#handle} should proceed to be called. Generally, you don't need to override
    # this as {#handle} can include the logic.  Where this is useful is to share cross-cutting logic
    # across other handlers.
    #
    # @return [URI|Brut::FrontEnd::Component,Array,Brut::FrontEnd::HttpStatus,Brut::FrontEnd::Download] See
    #         {#handle} for what each return value means.
    def before_handle = nil

    # Called by Brut to handle the request. Do not override this. If your handler responds to `before_handle` that is called with the
    # same args as you have defined for {#handle}. If `before_handle` returns anything other than `nil`, that value is returned and
    # should be one of the values documented in {#handle}.  If `before_handle` returns `nil`, {#handle} is called and whatever it
    # returns is returned here.
    def handle!(**args)
      result = nil
      result = self.before_handle
      if result.nil?
        result = self.handle(**args)
      end
      result
    end
  end
  # Namespace for handlers provided by Brut
  module Handlers
    autoload(:CspReportingHandler,"brut/front_end/handlers/csp_reporting_handler")
    autoload(:LocaleDetectionHandler,"brut/front_end/handlers/locale_detection_handler")
    autoload(:MissingHandler,"brut/front_end/handlers/missing_handler")
    autoload(:InstrumentationHandler,"brut/front_end/handlers/instrumentation_handler")
  end
end
