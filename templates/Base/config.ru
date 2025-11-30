require_relative "app/bootstrap"
bootstrap = Bootstrap.new.bootstrap!

app = Rack::Builder.app do
  use Rack::Session::Cookie,
    key: "rack.session",
    path: "/",
    expire_after: 31_536_000,
    same_site: :lax, # this allows links from other domains to send our cookies to us,
                     # but only if such links are direct/obvious to the user.
    secret: ENV.fetch("SESSION_SECRET")

  run bootstrap.rack_app
end
run app

