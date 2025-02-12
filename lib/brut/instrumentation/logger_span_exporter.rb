# Based on OpenTelemetry::SDK::Trace::Export::ConsoleSpanExporter, but designed to 
# log spans in a more traditional log-style format.
class Brut::Instrumentation::LoggerSpanExporter
  def initialize
    @stopped = false
    @child_spans = {}
  end

  NO_PARENT = "0000000000000000"

  def export(spans, timeout: nil)
    if @stopped
      return failure
    end

    Array(spans).each do |span|
      if span.hex_parent_span_id == NO_PARENT
        log_span(span:,indent: 0)
      else
        @child_spans[span.hex_parent_span_id] ||= []
        @child_spans[span.hex_parent_span_id] << span
      end
    end

    success
  end

  def force_flush(timeout: nil)
    success
  end

  def shutdown(timeout: nil)
    @stopped = true
    success
  end

private

  def failure = OpenTelemetry::SDK::Trace::Export::FAILURE
  def success = OpenTelemetry::SDK::Trace::Export::SUCCESS

  def log_span(span:,indent:)
    SemanticLogger[self.class].info(
      (" " * indent) +
      span.name +
      " [#{((span.end_timestamp - span.start_timestamp)/1_000.0).to_i/1_000.0}ms] {" +
      span.attributes.map { |key,value| "#{key}='#{value}'" }.join("; ") +
      "}"
    )

    previous_timestamp = span.start_timestamp
    (span.events || []).each do |event|
      SemanticLogger[self.class].info(
        (" " * (indent + 2)) + "event:#{event.name}" +
        " [#{((event.timestamp - previous_timestamp)/1_000.0).to_i/1_000.0}ms later] {" +
        event.attributes.map { |key,value| "#{key}='#{value}'" }.join("; ") +
        "}"
      )
      previous_timestamp = event.timestamp
    end

    hex_span_id = span.hex_span_id
    (@child_spans[hex_span_id] || []).each do |child_span|
      log_span(span: child_span, indent: indent + 4)
    end
    @child_spans[hex_span_id] = []
  end

end
