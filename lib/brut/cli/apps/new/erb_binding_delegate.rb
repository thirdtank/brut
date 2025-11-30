# This exists because ERB can't working with a SimpleDelegator or
# Delegate.
class Brut::CLI::Apps::New::ErbBindingDelegate
  attr_reader :app_name, :versions
  def initialize(options:, app_name:, versions:)
    @options  = options
    @app_name = app_name
    @versions = versions
  end

  # Not using Delegate because it won't work with ERB binding
  def method_missing(syn,*args,&block)
    if args.empty? && @options.respond_to?(syn)
      @options.send(syn)
    else
      super
    end
  end

  def respond_to_missing?(syn,include_all)
    @options.respond_to?(syn)
  end
end
