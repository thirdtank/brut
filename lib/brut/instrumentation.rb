module Brut::Instrumentation
  autoload(:OpenTelemetry,"brut/instrumentation/open_telemetry")
  autoload(:LoggerSpanExporter,"brut/instrumentation/logger_span_exporter")

  def span(name,**attributes,&block)
    Brut.container.instrumentation.span(name,**attributes,&block)
  end
end

