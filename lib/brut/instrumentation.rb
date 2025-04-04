module Brut::Instrumentation
  autoload(:OpenTelemetry,"brut/instrumentation/open_telemetry")
  autoload(:LoggerSpanExporter,"brut/instrumentation/logger_span_exporter")

  # Convenience method to add attributes to create a span without accessing the instrumentation instance directly.
  def span(name,**attributes,&block)
    Brut.container.instrumentation.span(name,**attributes,&block)
  end
end

