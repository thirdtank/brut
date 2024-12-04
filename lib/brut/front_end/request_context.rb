class Brut::FrontEnd::RequestContext
  def initialize(env:,session:,flash:,xhr:,body:)
    @hash = {
      env:,
      session:,
      flash:,
      xhr:,
      body:,
      csrf_token: Rack::Protection::AuthenticityToken.token(env["rack.session"]),
      clock: Clock.new(session.timezone),
    }
  end


  def []=(key,value)
    key = key.to_sym
    @hash[key] = value
  end

  def fetch(key)
    if self.key?(key)
      value = self[key]
      if value
        return value
      else
        raise ArgumentError,"No key '#{key}' in #{self.class}"
      end
    else
      raise ArgumentError,"Key '#{key}' is nil in #{self.class}"
    end
  end

  def [](key)
    @hash[key.to_sym]
  end

  def key?(key)
    @hash.key?(key.to_sym)
  end

  # Returns a hash suitable to passing into this class' constructor.
  def as_constructor_args(klass, request_params:, route:nil)
    args_for_method(method: klass.instance_method(:initialize), request_params:, form: nil, route:)
  end

  def as_method_args(object, method_name, request_params:,form:,route:nil)
    args_for_method(method: object.method(method_name), request_params:, form:,route:)
  end

private

  def args_for_method(method:, request_params:, form:,route:)
    args = {}
    method.parameters.each do |(type,name)|

      if name.to_s == "**" || name.to_s == "*"
        raise ArgumentError,"#{method.class}##{method.name} accepts '#{name}' and not keyword args. Define it in your class to accept the keyword arguments your method needs"
      end
      if ![ :key,:keyreq ].include?(type)
        raise ArgumentError,"#{name} is not a keyword arg, but is a #{type}"
      end

      if self.key?(name)
        args[name] = self[name]
      elsif !form.nil? && name == :form
        args[name] = form
      elsif !route.nil? && name == :route
        args[name] = route
      elsif !request_params.nil? && (request_params[name.to_s] || request_params[name.to_sym])
        args[name] = request_params[name.to_s] || request_params[name.to_sym]
      elsif type == :keyreq
        request_params_message = if request_params.nil?
                                   "no request params provied"
                                 else
                                   "request_params: #{request_params.keys.map(&:to_s).join(", ")}"
                                 end
        raise ArgumentError,"#{method} argument '#{name}' is required, but there is no value in the current request context (keys: #{@hash.keys.map(&:to_s).join(", ")}, #{request_params_message}, form: #{form.class}). Either set this value in the request context or set a default value in the initializer"
      else
        # this keyword arg has a default value which will be used
      end
    end
    args
  end
end
