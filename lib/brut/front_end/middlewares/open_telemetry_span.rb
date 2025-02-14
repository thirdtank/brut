class Brut::FrontEnd::Middlewares::OpenTelemetrySpan < Brut::FrontEnd::Middleware
  def initialize(app)
    @app = app
  end
  def call(env)
    path = env["REQUEST_PATH"]
    method = env["REQUEST_METHOD"]
    Brut.container.instrumentation.span("HTTP.#{method}.#{path}") do |span|
      @app.call(env)
    end
  end
end
