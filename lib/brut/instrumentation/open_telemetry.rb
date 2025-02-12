class Brut::Instrumentation::OpenTelemetry
  # Create a span around the given block of code.
  #
  # @param [String] name the name of the span. Should be specific to the code being wrapped, but not contain dynamic information. For
  # example, you could call this the method name, but should not include parameters in the name.
  # @param [Hash<String|Symbol,Object>] attributes Hash of attributes to include in this span. This is as if you called
  # {Brut::Instrumentation::OpenTelemetry::Span#add_attributes} as the first line of the block.  See that method for more details on
  # the contents of this hash.
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
    Brut.container.tracer.in_span(name) do |span|
      wrapped_span = Span.new(span)
      wrapped_span.add_attributes(attributes)
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

  def record_exception(ex,attributes=nil)
    current_span = OpenTelemetry::Trace.current_span
    current_span.record_exception(ex,attributes: NormalizedAttributes.new(nil,attributes).to_h)
  end

  # Adds attributes to the current span
  # @param [Hash] attributes any attributes to attach to the event.
  def add_attributes(attributes)
    current_span = OpenTelemetry::Trace.current_span
    current_span.add_attributes(NormalizedAttributes.new(nil,attributes).to_h)
  end

  class NormalizedAttributes
    def initialize(prefix,attributes)
      prefix = if prefix
                 "#{prefix}."
               else
                 ""
               end
      @attributes = (attributes || {}).map { |key,value|
        [ "#{prefix}#{key}", normalize_value(value) ]
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

    # Adds attributes to the span, converting the hash or keyword arguments to strings.
    #
    # @param [Hash] attributes a hash of the attributes to add. Keys will be converted to strings via `to_s`.
    # Values will be converted via {Brut::Instrumentation::OpenTelemetry::NormalizedAttributes}, which preserves strings, numbers, and
    # booleans, and converts the rest to strings via `to_s`.
    def add_attributes(attributes)
      add_prefixed_attributes(nil,attributes)
    end

    # Adds attributes to the span, prefixing each key with the given prefix, then converting the hash or keyword arguments to strings.
    #
    # @see #add_attributes
    def add_prefixed_attributes(prefix,attributes)
      __getobj__.add_attributes(
        NormalizedAttributes.new(prefix,attributes).to_h
      )
    end
  end
end
