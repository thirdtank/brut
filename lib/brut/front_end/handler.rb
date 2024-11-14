# A handler responds to all HTTP requests other than those that render a page. It will be given any data it needs
# to handle the request to its handle method.  You define this method to accept the parameters you expect.
#
# You may also define before_handle which will be given any subset of those parameters and can perform logic before
# handle is called.  This is most useful in a base class to check for permissions or other cross-cutting concerns.
#
# Tests should call handle!
module Brut::FrontEnd
  class Handler
    include Brut::FrontEnd::HandlingResults

    def handle(**)
      raise Brut::Framework::Errors::AbstractMethod
    end

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
  module Handlers
    autoload(:CspReportingHandler,"brut/front_end/handlers/csp_reporting_handler")
    autoload(:LocaleDetectionHandler,"brut/front_end/handlers/locale_detection_handler")
  end
end
