class Brut::FrontEnd::Middlewares::OpenTelemetrySpan < Brut::FrontEnd::Middleware
  def initialize(app)
    @app = app
  end
  def call(env)
    Brut.container.instrumentation.span("brut.request") do |span|
      span.add_prefixed_attributes("brut.request",
        path: env["REQUEST_PATH"],
        method: env["REQUEST_METHOD"],
      )
      @app.call(env)
    end
  end
end
