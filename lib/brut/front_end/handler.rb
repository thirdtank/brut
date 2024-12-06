module Brut::FrontEnd
  # A handler responds to all HTTP requests other than those that render a page. It will be given any data it needs
  # to handle the request to its {#handle} method, which you must implement. 
  # You define this method to accept the parameters you expect. See {Brut::FrontEnd::RequestContext} for how that works.
  #
  # You may also define `before_handle` which will be given any subset of those parameters and can perform logic before
  # handle is called.  This is most useful in a base class to check for permissions or other cross-cutting concerns.
  #
  # The primary method of this class is {#handle!} which you should not override, but *should* call in a test.
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
    #
    # @return [URI|Brut::FrontEnd::Component,Array,Brut::FrontEnd::HttpStatus,Brut::FrontEnd::Download]
    def handle(**)
      abstract_method!
    end

    # Called by Brut to handle the request. Do not override this. If your handler responds to `before_handle` that is called with the
    # same args as you have defined for {#handle}. If `before_handle` returns anything other than `nil`, that value is returned and
    # should be one of the values documented in {#handle}.  If `before_handle` returns `nil`, {#handle} is called and whatever it
    # returns is returned here.
    def handle!(**args)
      result = nil
      if self.respond_to?(:before_handle)
        before_handle_args = self.method(:before_handle).parameters.map { |(type,name)|
          if type == :keyreq
            if args.key?(name)
              [ name, args[name] ]
            else
              raise ArgumentError,"before_handle requires keyword arg '#{name}' but `handle` did not receive it. It must"
            end
          elsif type == :key
            if args.key?(name)
              [ name, args[name] ]
            else
              nil
            end
          else
            raise ArgumentError,"before_handle must only have keyword args. Got '#{name}' of type '#{type}'"
          end
        }.compact.to_h
        result = self.before_handle(**before_handle_args)
      end
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
  end
end
