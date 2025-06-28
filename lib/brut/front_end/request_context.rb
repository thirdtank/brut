# Container for request-specific information that serves as the source of what can be automaticall passed to various methods by Brut.
#
# The intention for this class is to provide access to the 80% of stuff needed by most requests, to alleviate the need to have to dig
# into `env` or the Rack request.  This also allows arbitrary information to be inserted and made available later.
#
# Several methods of Brut objects take keyword arguments in their initializer or a particular method.  The names of those keyword
# arguments correspond to values that are contained by this class.  Thus, if you are creating, say, a {Brut::FrontEnd::Page} subclass,
# and create an initializer for it that accepts the `clock:` keyword argument, the managed instance of {Clock} will be passed into it
# when Brut creates an instance of the class.
class Brut::FrontEnd::RequestContext

  def self.current
    Thread.current.thread_variable_get(:request_context)
  end

  # Create an instance of klass injected with the request context.
  def self.inject(klass, request_params: nil)
    self.current.then { |request_context|
      request_context.as_constructor_args(klass,request_params:)
    }.then { |constructor_args|
      klass.new(**constructor_args) 
    }
  end
  # Create a new RequestContext based on some of the information provided by Rack
  #
  # @param [Hash] env the Rack `env` object, as available to any middleware
  # @param [Brut::FrontEnd::Session] session the current session, noting that this is the Brut (or your app) session class and not the Rack session.
  # @param [Brut::FrontEnd::Flash] flash the current flash
  # @param [true|false] xhr true if this is an XHR request.
  # @param [Object] body the `request.body` as provided by Rack
  # @param [URI] host URI the `request.host` and `request.scheme`, and `request.port` as provided by Rack
  def initialize(env:,session:,flash:,xhr:,body:,host:)
    @hash = {
      env:,
      session:,
      flash:,
      xhr:,
      body:,
      host:,
      csrf_token: Rack::Protection::AuthenticityToken.token(env["rack.session"]),
      clock: Clock.new(session.timezone),
    }
  end


  # Set an arbitrary value that can be injected later
  # @param [String|Symbol] key the name of the value. This is converted to a symbol.
  # @param [Object] value the value to map. Should not be nil.
  def []=(key,value)
    key = key.to_sym
    @hash[key] = value
  end

  # Access the given value, raising an exception if it has not been set or if it's nil. 
  # @param [String|Symbol] key the value to fetch.
  #
  # @return [Object] the mapped value
  #
  # @raise [ArgumentError] if `key` was never mapped or maps to `nil`.
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

  # Access a given value, returning `nil` if it's not mapped or is `nil`
  # @param [String|Symbol] key the value to get
  # @return [Object] the mapped value
  def [](key)
    @hash[key.to_sym]
  end

  # Check if a given value has been mapped.
  # @param [String|Symbol] key the value to check
  # @return [true|false] if the value is mapped. Note that if `nil` was injected, this method returns `true`.
  def key?(key)
    @hash.key?(key.to_sym)
  end

  # Based on `klass`' constructor, returns a Hash that maps all keywords it requires to the values stored in this
  # `RequestContext`. It is assumed that `request_params:` contains the query parameters so they can be injected.
  # The {Brut::FrontEnd::Routing::Route} can also be injected to pass in.
  #
  # @example
  #     class SomeClass
  #       def initialize(flash:,clock:,date:)
  #         # ...
  #       end
  #     end
  #    
  #     hash = request_context.as_constructor_args(
  #       SomeClass,
  #       request_params: { date: "2024-11-11" }
  #     )
  #    
  #     # hash contains:
  #     # {
  #     #   flash: «Flash used to create the RequestContext»,
  #     #   clock: «Clock used to create the RequestContext»,
  #     #   date: "2024-11-11",
  #     # }
  #    
  #     object = SomeClass.new(**hash)
  #
  # @param [Class] klass a class that is to be instantiated entirely by the contents of this `RequestContext`.
  # @param [Hash] request_params Query string parameters provided by Rack.
  # @param [Brut::FrontEnd::Routing::Route] route the route that triggered the request.
  # @param [Brut::FrontEnd::Form] form the form, if available
  # @return [Hash] can be splatted to keyword arguments and passed to the constructor of `klass`
  #
  # @raise [ArgumentError] if the constructor has any non-keyword arguments, or if any required keyword argument is
  #                        not present in this `RequestContext`.
  def as_constructor_args(klass, request_params:, route:nil, form: nil)
    args_for_method(method: klass.instance_method(:initialize), request_params:, form: , route:)
  end

  # Based on `object`' method, returns a Hash that maps all keywords it requires to the values stored in this
  # `RequestContext`. It is assumed that `request_params:` contains the query parameters so they can be injected.
  # It is also assumed that `form:` is the {Brut::FrontEnd::Form} that is provided as part of the request.
  # The {Brut::FrontEnd::Routing::Route} can also be injected to pass in.
  #
  # @example
  #     class SomeClass
  #       def doit(flash:,clock:,date:)
  #         # ...
  #       end
  #     end
  #    
  #     object = SomeClass.new
  #    
  #     hash = request_context.as_method_args(
  #       object,
  #       :doit,
  #       request_params: { date: "2024-11-11" }
  #     )
  #    
  #     # hash contains:
  #     # {
  #     #   flash: «Flash used to create the RequestContext»,
  #     #   clock: «Clock used to create the RequestContext»,
  #     #   date: "2024-11-11",
  #     # }
  #    
  #     result = object.doit(**hash)
  #
  # @param [Class] object an object whose method is to be called that requires some of the contents of this `RequestContext`.
  # @param [Symbol] method_name name of the method that will be called.
  # @param [Hash] request_params Query string parameters provided by Rack. Note that any parameter whose value is the empty string will be coerced to `nil`.
  # @param [Brut::FrontEnd::Routing::Route] route the route that triggered the request.
  # @param [Brut::FrontEnd::Form] form the form that was submitted with this request. May be `nil`.
  # @return [Hash] can be splatted to keyword arguments and passed to the constructor of `klass`
  #
  # @raise [ArgumentError] if the method has any non-keyword arguments, or if any required keyword argument is
  #                        not present in this `RequestContext`.
  def as_method_args(object, method_name, request_params:,form:,route:nil)
    args_for_method(method: object.method(method_name), request_params:, form:,route:)
  end

private

  def args_for_method(method:, request_params:, form:,route:)
    args = {}
    rack_request = Rack::Request.new(self[:env])
    method.parameters.each do |(type,name)|

      if name.to_s == "**" || name.to_s == "*"
        raise ArgumentError,"#{method.class}##{method.name} accepts '#{name}' and not keyword args. Define it in your class to accept the keyword arguments your method needs"
      end
      if ![ :key,:keyreq ].include?(type)
        raise ArgumentError,"#{name} is not a keyword arg, but is a #{type}"
      end

      if self.key?(name)
        args[name] = self[name]
      elsif name.to_s =~ /^http_[^_]+/
        header_value = self[:env][name.to_s.upcase]
        if header_value
          args[name] = header_value
        elsif type == :keyreq
          args[name] = nil
        end
      elsif name.to_s =~ /^rack_request_[^_]+/ &&
        rack_request.respond_to?(name.to_s.sub(/^rack_request_/,""))
        value = rack_request.send(name.to_s.sub(/^rack_request_/,""))
        if value
          args[name] = value
        elsif type == :keyreq
          args[name] = nil
        end
      elsif !form.nil? && name == :form
        args[name] = form
      elsif !route.nil? && name == :route
        args[name] = route
      elsif !request_params.nil? && (request_params[name.to_s] || request_params[name.to_sym])
        args[name] = RichString.new(request_params[name.to_s] || request_params[name.to_sym]).to_s_or_nil
      elsif name == :raw_params
        args[name] = request_params || {}
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
