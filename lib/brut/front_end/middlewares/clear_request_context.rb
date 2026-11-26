class Brut::FrontEnd::Middlewares::ClearRequestContext < Brut::FrontEnd::Middleware
  def initialize(app)
    @app = app
  end
  def call(env)
    @app.call(env)
  ensure
    Thread.current.thread_variable_set(:request_context,nil)
  end
end
