# An "App" in Brut paralance is the collection of source code and configuration that is needed to operate
# a website. This includes everything needed to serve HTTP requests, but also includes ancillary
# tasks and any related files required for the app to exist and function.
# Your app will have an `App` class that subclasses this class.
#
# When your app is initialized, Brut will have been configured,
# but access to internal resources may not be available.  It is here
# that you can override configuration values or do any other setup before everything boots.
class Brut::Framework::App
  include Brut::Framework::Errors

  # An identifier for this app that can be used as a hostname. Your app must provide this.
  def id
    abstract_method!
  end

  # An identifier for the app's 'organization' that can be used as a hostname.
  # This isn't relevant in all contexts, but is useful for deploys or other
  # actions where an app needs to exist inside some organizational context.
  def organization = id

  # Call this in your app's definition to define your app's routes.
  # The contents of the block will be evaluated in the context of
  # {Brut::SinatraHelpers::ClassMethods}, and the methods there are generally the ones you should be calling.
  #
  # You can call this multiple times and the routes will be concatenated together.
  def self.routes(&block)
    @routes_blocks ||= []
    if block.nil?
      @routes_blocks
    else
      @routes_blocks << block
    end
  end

  # Call this to specify what happens when an unhandled exception occurs.  You may call this mulitple times,
  # however note that if an error is caught that matches more than one block's condition, the one that is called
  # will be the first one declared.
  #
  # The only deviation from this rule is when you call this
  # without any condition.  Doing that establishes the behavior for a "catch all" handler, which is
  # only called when no other configured block can handle the exception. You can declare
  # this at any time. **Do note** the "catch all" handler is more of a best effort. Brut is currently
  # based on Sinatra which provides no way to arbitrarily catch all exceptions.  What Brut does here is to 
  # explicitly catch the range of http status codes from 400 to 999.
  #
  # Note that Brut will record the exception via OpenTelemetry so you should not do this in your handlers.  It
  # would be preferable to instead record an event if you want to have observability from your error handlers.
  #
  # @param [Class|Integer|Range<Integer>] condition if given this specifies the conditions under which the given
  #        block will handle the error.  If omitted, this block will handle any error that doesn't have a more
  #        specific handler configured.  Meaning of values:
  #        * A class - this is an exception class that, if caught, triggers the handler
  #        * An integer - this is an HTTP status code that, if returned, triggers the handler
  #        * A range of integers - this is a range of HTTP status codes that, if returned, triggers the handler
  # @yield [Exception] the block is given two named parameters: `exception:` and `http_status_code:`. Your block
  #        can declare both, either, or none.  Any that are declared will be given values.  At least one
  #        will be non-`nil`, however are encouraged to code defensively inside this block.
  # @yieldparam [Exception] exception: the exception that was raised. This will be `nil`
  #             if the error was caused by an HTTP status code.
  # @yieldparam [Integer] http_status_code: the HTTP status code that was returned. If `exception:` is
  #             not `nil`, this value is highly likely to be 500.
  # @yieldreturn The block should return a valid Rack response. For now.
  def self.error(condition=:catch_all, &block)
    @error_blocks ||= {}
    if block.nil?
      raise ArgumentError, "You must provide a block to error"
    end
    parameters = block.parameters.reject { |type,name|
      type == :keyreq && [ :http_status_code, :exception ].include?(name)
    }
    if parameters.any?
      messages = parameters.map { |type,name|
        case type
        when :keyreq
          "required keyword parameter '#{name}:'"
        when :key
          "optional keyword parameter '#{name}:'"
        when :rest
          "rest parameter '#{name}'"
        when :opt
          "optional parameter '#{name}'"
        when :req
          "required parameter '#{name}'"
        else
          "unknown parameter '#{name}'"
        end
      }
      raise ArgumentError, "Your error handler block may only accept exception: and http_status_code: as required keyword parameters.  The following parameters were found:\n  #{messages.join("\n  ")}"
    end
    if @error_blocks[condition]
      raise ArgumentError, "You have already configured error handling for condition '#{condition.to_s}'"
    end
    @error_blocks[condition] = block
  end

  def self.error_blocks = @error_blocks || {}

  # Add a Rack middleware to your app. Middlewares are configured in the order in which you call this method.
  #
  # @param [Class] middleware a class that implements [Rack Middleware](https://github.com/rack/rack/blob/main/SPEC.rdoc).
  # @param [Array] args arguments to be given to the `middleware` class' initializer.
  # @param [block] block a block that is given to the initializer of the `middleware` class.
  #
  # @return [Array] if no parameters are given, returns all the currently-configured middleware.
  def self.middleware(middleware=nil,*args,&block)
    @middlewares ||= []
    if middleware.nil? && args.empty? && block.nil?
      @middlewares
    else
      @middlewares << [ middleware, args, block ]
    end
  end

  # Configure a {Brut::FrontEnd::RouteHook} to be called before each request.
  #
  # @param [String] klass_name The name of the class that extends {Brut::FrontEnd::RouteHook} and implements #before.  This uses the
  #                            name (not the class itself) to avoid loading issues.
  #
  # @return [Array] If no parameters given, returns all configured before hooks.
  def self.before(klass_name=nil)
    @before ||= []
    if klass_name.nil?
      @before
    else
      @before << klass_name
    end
  end

  # Configure a {Brut::FrontEnd::RouteHook} to be called after each request.
  #
  # @param [String] klass_name The name of the class that extends {Brut::FrontEnd::RouteHook} and implements #after.  This uses the
  #                            name (not the class itself) to avoid loading issues.
  #
  # @return [Array] If no parameters given, returns all configured after hooks.
  def self.after(klass_name=nil)
    @after ||= []
    if klass_name.nil?
      @after
    else
      @after << klass_name
    end
  end

  # Override this to set up any runtime connections or execute other pre-flight
  # code required *after* Brut has been set up and started.  You can rely on the
  # database being available. Any attempts to override configuration values
  # may not succeed.  This is called after the framework has booted, but before
  # your app's routes are set up.
  def boot!
  end

end
