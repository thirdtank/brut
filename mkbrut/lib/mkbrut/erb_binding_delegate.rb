# This exists because ERB can't working with a SimpleDelegator or
# Delegate.
class MKBrut::ErbBindingDelegate
  def initialize(app_options)
    @app_options = app_options
  end

  # Not using Delegate because it won't work with ERB binding
  def method_missing(syn,*args,&block)
    if args.empty? && @app_options.respond_to?(syn)
      @app_options.send(syn)
    else
      super
    end
  end

  def respond_to_missing?(syn,include_all)
    @app_options.respond_to?(syn)
  end
end
