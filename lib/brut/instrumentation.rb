# Namespace for instrumentation setup and support.  Brut strives to provide useful
# instrumentation by default.
#
module Brut::Instrumentation
  autoload(:OpenTelemetry,"brut/instrumentation/open_telemetry")
  autoload(:LoggerSpanExporter,"brut/instrumentation/logger_span_exporter")
  autoload(:Methods,"brut/instrumentation/methods")
end

