# Handles requests for `/favicon.ico` by redirecting the browser to `/static/images/favicon.ico`.
class Brut::FrontEnd::Middlewares::Favicon < Brut::FrontEnd::Middleware
  def initialize(app)
    @app = app
  end
  def call(env)
    if env["PATH_INFO"] =~ /^\/favicon.ico/
      return [
        301,
        { "location" => "/static/images/favicon.ico" },
        [],
      ]
    end
    @app.call(env)
  end
end
