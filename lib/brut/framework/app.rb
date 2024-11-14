# An "App" in Brut paralance is the collection of source code and configure that is needed to operate
# a website. This includes everything needed to serve HTTP requests, but also includes ancillary
# tasks and any related files required for the app to exist and function.
class Brut::Framework::App

  # An identifier for this app that can be used as a hostname
  def id = raise "Subclass must implement"

  # An identifier for the app's 'organization' that can be used as a hostname.
  # This isn't relevant in all contexts, but is useful for deploys or other
  # actions where an app needs to exist inside some organizational context.
  def organization = id

  def self.routes(&block)
    @routes_blocks ||= []
    if block.nil?
      @routes_blocks
    else
      @routes_blocks << block
    end
  end
  def self.middleware(middleware=nil,*args,&block)
    @middlewares ||= []
    if middleware.nil? && args.empty? && block.nil?
      @middlewares
    else
      @middlewares << [ middleware, args, block ]
    end
  end
  def self.before(klass_name=nil)
    @before ||= []
    if klass_name.nil?
      @before
    else
      @before << klass_name
    end
  end
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
  # your apps routes are set up.
  def boot!
  end

end
