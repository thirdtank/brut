# Renders the traceparent value for the current trace so that the front-end can add additional spans.
class Brut::FrontEnd::Components::Traceparent < Brut::FrontEnd::Component
  def initialize
    propagator = OpenTelemetry::Trace::Propagation::TraceContext::TextMapPropagator.new
    carrier = {}
    current_context = OpenTelemetry::Context.current
    propagator.inject(carrier, context: current_context)
    @traceparent = carrier.fetch("traceparent")
  end

  def render
    html_tag(:meta, name: "traceparent", content: @traceparent)
  end
end
