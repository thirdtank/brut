# Annotates any path that is owned by Brut as such. Alleviates downstream code from having to include the actual
# path determination Brut uses.  After this middleware has run, `env["brut.owned_path"]` will return `true` if the path
# represents one that Brut is managing.
class Brut::FrontEnd::Middlewares::AnnotateBrutOwnedPaths < Brut::FrontEnd::Middleware
  def initialize(app)
    @app = app
  end
  def call(env)
    if env["PATH_INFO"] =~ /^\/__brut\//
      Brut.container.instrumentation.add_attributes("brut.owned_path" => true)
      env["brut.owned_path"] = true
    end
    @app.call(env)
  end
end
