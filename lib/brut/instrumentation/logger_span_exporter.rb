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
      SemanticLogger[self.class].warn "Attempt to export spans after exporter was shut down"
      return failure
    end

    Array(spans).each do |span|
      if span.hex_parent_span_id == NO_PARENT
        log_span(span:,indent: 0)
      elsif span.attributes["http.user_agent"]
        log_span(span:,indent: 0, synthetic_attributes: { browser: true })
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
    if @child_spans.any?
      SemanticLogger[self.class].warn "There were #{@child_spans.length} spans un-logged"
    end
    success
  end

private

  def failure = OpenTelemetry::SDK::Trace::Export::FAILURE
  def success = OpenTelemetry::SDK::Trace::Export::SUCCESS

  def log_span(span:,indent:, synthetic_attributes: {})
    SemanticLogger.tagged(trace_id: span.hex_trace_id) do
      message = (" " * indent) + span.name
      params = {
        timing: ((span.end_timestamp - span.start_timestamp)/1_000.0).to_i/1_000.0,
      }.merge(span.attributes).merge(synthetic_attributes)

      SemanticLogger[self.class].info(message, params)

      previous_timestamp = span.start_timestamp
      (span.events || []).each do |event|
        event_message = (" " * (indent + 2)) + "event:#{event.name}"
        event_params = {
          timing: ((event.timestamp - previous_timestamp)/1_000.0).to_i/1_000.0,
        }.merge(event.attributes).merge(synthetic_attributes)
        SemanticLogger[self.class].info(event_message,event_params)
        previous_timestamp = event.timestamp
      end

      hex_span_id = span.hex_span_id
      (@child_spans[hex_span_id] || []).each do |child_span|
        log_span(span: child_span, indent: indent + 4)
      end
      @child_spans.delete(hex_span_id)
    end
  end

end
