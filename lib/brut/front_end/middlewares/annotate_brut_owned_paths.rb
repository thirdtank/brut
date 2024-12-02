class Brut::FrontEnd::Middlewares::AnnotateBrutOwnedPaths < Brut::FrontEnd::Middleware
  def initialize(app)
    @app = app
  end
  def call(env)
    if env["PATH_INFO"] =~ /^\/__brut\//
      env["brut.owned_path"] = true
    end
    @app.call(env)
  end
end
