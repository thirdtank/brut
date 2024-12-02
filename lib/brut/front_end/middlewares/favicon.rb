class Brut::FrontEnd::Middlewares::Favicon < Brut::FrontEnd::Middleware
  def initialize(app)
    @app = app
  end
  def call(env)
    SemanticLogger[self.class].info "Checking '#{env['PATH_INFO']}' against favicon.ico"
    if env["PATH_INFO"] =~ /^\/favicon.ico/
      SemanticLogger[self.class].info "Got it! Redirection elsewhere"
      return [
        302,
        { "location" => "/static/images/favicon.ico" }
      ]
    end
    @app.call(env)
  end
end
