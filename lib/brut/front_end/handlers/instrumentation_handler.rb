require "base64"
class Brut::FrontEnd::Handlers::InstrumentationHandler < Brut::FrontEnd::Handler
  Event = Data.define(:name, :timestamp, :attributes) do
    def self.from_json(json)
      name       = json["name"]
      timestamp  = Time.at(json["timestamp"].to_i / 1000.0)
      attributes = json["attributes"] || {}
      self.new(name:,timestamp:,attributes:)
    end
  end

  Span = Data.define(:name,:start_timestamp,:end_timestamp,:attributes,:events,:spans) do
    def self.from_json(json)
      name            = json["name"]
      start_timestamp = Time.at(json["start_timestamp"].to_i / 1000.0)
      end_timestamp   = Time.at(json["end_timestamp"].to_i / 1000.0)
      attributes      = json["attributes"] || {}
      events          = (json["events"] || []).map { Event.from_json(it) }
      spans           = (json["spans"] || []).map { Span.from_json(it) }
      self.new(name:,start_timestamp:,end_timestamp:,attributes:,events:,spans:)
    end

    def self.from_header(header_value)
      if header_value.nil?
        return nil
      end
      if header_value.kind_of?(self)
        return header_value
      end

      # This header can have info for several vendors, delimited by commas. We pick
      # out ours, which has a vendor name 'brut'
      brut_state = header_value.split(/\s*,\s*/).map { it.split(/\s*=\s*/) }.detect { |vendor,_|
        vendor == "brut"
      }[1]

      # Our state is a base-64 encoded JSON blob
      # each key/value separated by a colon.
      json = Base64.decode64(brut_state)

      hash = JSON.parse(json)
      if !hash.kind_of?(Hash)
        SemanticLogger[self.class].info "Got a #{hash.class} and not a Hash"
        return nil
      end
      self.from_json(hash)
    end
  end

  class TraceParent
    def self.from_header(header_value)
      if header_value.nil?
        return nil
      elsif header_value.kind_of?(self)
        return header_value
      else
        return TraceParent.new(header_value)
      end
    end

    def initialize(value)
      @value = value
    end

    def as_carrier = { "traceparent" => @value }
  end

  def initialize(http_tracestate:, http_traceparent:)
    @http_tracestate  = http_tracestate
    @http_traceparent = http_traceparent
  end
  def handle
    traceparent = TraceParent.from_header(@http_traceparent)
    span        = Span.from_header(@http_tracestate)

    if span.nil? || traceparent.nil?
      SemanticLogger[self.class].info "Missing traceparent or span: #{@http_tracestate}, #{@http_traceparent}"
      return http_status(400)
    end

    carrier = traceparent.as_carrier
    propagator = OpenTelemetry::Trace::Propagation::TraceContext::TextMapPropagator.new
    extracted_context = propagator.extract(carrier)
    OpenTelemetry::Context.with_current(extracted_context) do
      record_span(span)
    end
    http_status(200)
  end

private

  def record_span(span)
    otel_span = Brut.container.tracer.start_span(span.name, start_timestamp: span.start_timestamp, attributes: span.attributes)
    span.events.each do |event|
      otel_span.add_event(event.name,timestamp: event.timestamp, attributes: event.attributes)
    end
    span.spans.each do |inner_span|
      record_span(inner_span)
    end
    otel_span.finish(end_timestamp: span.end_timestamp)
  end

end
