class Brut::FrontEnd::Middlewares::ClearRequestContext < Brut::FrontEnd::Middleware
  def initialize(app)
    @app = app
  end
  def call(env)
    @app.call(env)
  ensure
    Brut::FrontEnd::RequestContext.clear_current!
  end
end
