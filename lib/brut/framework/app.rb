# An "App" in Brut paralance is the collection of source code and configuration that is needed to operate
# a website. This includes everything needed to serve HTTP requests, but also includes ancillary
# tasks and any related files required for the app to exist and function.  Your app will have an `App` class that subclasses this
# class.
#
# When your app is initialized, Brut will have been configured, but access to internal resources may not be available.  It is here
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

  # Call this in your app's definition to define your app's routes. The contents of the block will be evaluated in the context of
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
  # your apps' routes are set up.
  def boot!
  end

end
