# Class to interact with the OpenTelemetry standard in a simpler way than
# the provided Ruby gem does.  In general, you should use this class
# via `Brut.container.instrumentation`, and you should *not* use the 
# OpenTelemetry ruby library directly.  You probably wouldn't want to, anyway.
class Brut::Instrumentation::OpenTelemetry
  # Create a span around the given block of code.
  #
  # @param [String] name the name of the span. Should be specific to the code being wrapped, but not contain dynamic information. For
  # example, you could call this the method name, but should not include parameters in the name.
  # @param [Hash<String|Symbol,Object>] attributes Hash of attributes to include in this span. This is as if you called {Brut::Instrumentation::OpenTelemetry::Span#add_attributes} as the first line of the block.  There is a special attribute named `prefix:` that will control how attributes are prefixed.  If it is missing, the app's configured OTel prefix is used. If it is sent to `false`, no prefixing is done. Otherwise, the provided value is used as the prefix.  Generally, you don't want to set this so your app's prefix is used. Also note that the keys and values are automatically converted to primitive types, so you can use whatever makes sense. Just know that for rich objects `to_s` will be called.
  #
  # @yield [Brut::Instrumentation::OpenTelemetry::Span] executes this block in the context of a new OpenTelemetry span. yields
  #                                                     the span so you can call further methods on it.
  # @yieldparam span [Brut::Instrumentation::OpenTelemetry::Span]
  # @yieldreturn [Object] Whatever is returned from the block is returned by this method
  # @return [Object] Whatever is returned from the block, unless an exception is raised.
  # @raise [Exception] if the block raises an exception, that exception will be raised, however `record_exception` will be called.
  #
  def span(name,**attributes,&block)
    result = nil
    normalized_attributes = NormalizedAttributes.new(:detect,attributes).to_h
    Brut.container.tracer.in_span(name, attributes: normalized_attributes) do |span|
      wrapped_span = Span.new(span)
      begin
        result = block.(wrapped_span)
      rescue => ex
        span.record_exception(ex)
        raise
      end
    end
    result
  end

  # Adds an event to the current span
  # @param [String] name the name of the event. Should not contain dynamic information.
  # @param [Hash] attributes any attributes to attach to the event.
  def add_event(name,**attributes)
    explicit_attributes = attributes.delete(:attributes) || {}
    timestamp = attributes.delete(:timestamp)
    current_span = OpenTelemetry::Trace.current_span
    current_span.add_event(name,
                           attributes: NormalizedAttributes.new(nil,attributes.merge(explicit_attributes)).to_h,
                           timestamp:)
  end

  # Record an exception.  In general, use this only if:
  #
  # * You need to have the parent span record this particular exception
  # * You are not going to re-raise the exception.
  #
  # Otherwise, look at {#record_and_reraise_exception!}.
  #
  # @param [Exception] ex the exception to record.
  # @param [Hash] attributes any attributes to attach that will show up in your OTel provider
  def record_exception(ex,attributes=nil)
    current_span = OpenTelemetry::Trace.current_span
    current_span.record_exception(ex,attributes: NormalizedAttributes.new(nil,attributes).to_h)
  end

  # Record an exception and re-raise it. This is useful if you want
  # the exception recorded as part of the parent span, but still plan
  # to let it raise.  Don't do this for every exception you intend to raise.
  # @param [Exception] ex the exception to record.
  # @param [Hash] attributes any attributes to attach that will show up in your OTel provider
  # @raise [Exception] the exception passed in.
  def record_and_reraise_exception!(ex,attributes=nil)
    reecord_exception(ex,attributes)
    raise ex
  end


  # Adds attributes to the span, converting the hash or keyword arguments to strings. This will use
  # the app's Otel prefix for all attributes, so you do not have to prefix them.
  # If you need to set standard attributes, you should use {#add_prefixed_attributes} instead.
  # @param [Hash] attributes any attributes to attach to the event.
  def add_attributes(attributes)
    current_span = OpenTelemetry::Trace.current_span
    current_span.add_attributes(NormalizedAttributes.new(:detect,attributes).to_h)
  end

  # Adds attributes to the span, prefixing each key with the given prefix, then converting the hash or keyword arguments to strings.  For example, if the prefix is 'my_app' and you add the attributes 'type' and 'reason', the actual attribute names will be 'my_app.type' and 'my_app.reason'.
  #
  # @see #add_attributes
  def add_prefixed_attributes(prefix,attributes)
    current_span = OpenTelemetry::Trace.current_span
    current_span.add_attributes(
      NormalizedAttributes.new(prefix,attributes).to_h
    )
  end

private

  class NormalizedAttributes
    def initialize(prefix,attributes)
      if prefix == :detect
        prefix = attributes.delete(:prefix)
        if prefix.nil?
          prefix = Brut.container.otel_attribute_prefix
        end
      end
      prefix_string = if prefix
                        "#{prefix}."
                      else
                        ""
                      end
      @attributes = (attributes || {}).map { |key,value|
        [ "#{prefix_string}#{key}", normalize_value(value) ]
      }.to_h
    end

    def to_h
      @attributes
    end

  private

    def normalize_value(value)
      case value
      when String then value
      when Numeric then value
      when true then true
      when false then false
      when Array then value.map { normalize_value(it) }
      else
        value.to_s
      end
    end

  end

  class Span < SimpleDelegator

    # Adds attributes to the span, converting the hash or keyword arguments to strings. This will use
    # the app's Otel prefix for all attributes, so you do not have to prefix them.
    # If you need to set standard attributes, you should use {#add_prefixed_attributes} instead.
    #
    # @param [Hash] attributes a hash of the attributes to add. Keys will be converted to strings via `to_s`.
    # Values will be converted via {Brut::Instrumentation::OpenTelemetry::NormalizedAttributes}, which preserves strings, numbers, and
    # booleans, and converts the rest to strings via `to_s`.
    def add_attributes(attributes)
      add_prefixed_attributes(:detect,attributes)
    end

    # Adds attributes to the span, prefixing each key with the given prefix, then converting the hash or keyword arguments to strings.  For example, if the prefix is 'my_app' and you add the attributes 'type' and 'reason', the actual attribute names will be 'my_app.type' and 'my_app.reason'.
    #
    # @see #add_attributes
    def add_prefixed_attributes(prefix,attributes)
      __getobj__.add_attributes(
        NormalizedAttributes.new(prefix,attributes).to_h
      )
    end
  end
end
