# Renders the traceparent value for the current trace so that the front-end can add additional spans.
class Brut::FrontEnd::Components::Traceparent < Brut::FrontEnd::Component2
  def initialize
    propagator = OpenTelemetry::Trace::Propagation::TraceContext::TextMapPropagator.new
    carrier = {}
    current_context = OpenTelemetry::Context.current
    propagator.inject(carrier, context: current_context)
    @traceparent = carrier["traceparent"]
  end

  def view_template
    attributes = {
      name: "traceparent",
      content: @traceparent,
    }
    if !@traceparent
      attributes["data-no-traceparent"] = "no traceparent was available - this component may have been rendered outside of an existing OpenTelemetry context"
    end
    meta(**attributes)
  end
end
