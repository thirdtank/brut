# Stores logic around what POST requests should require CSRF protection.
# Brut ideally wants *all* POST requests to require CSRF protection, however
# sometimes this is not convienient, notably webhooks.  This class includes
# that logic.
#
# You may specify your own implementation via
# `Brut.container.override("csrf_protector", YourCustomCsrfProtector.new)` in your `App` class' initializer.
#
# @example
#   class CsrfProtector < Brut::FrontEnd::CsrfProtector
#     def allowed?(env)
#       super(env) ||
#         !!env["PATH_INFO"].to_s.match?(/^\/api\//)
#     end
#   end
#   # Then, in app.rb
#   class App < Brut::Framework::App
#     def id           = "some-id"
#     def organization = "some-org"
#   
#     def initialize
#       Brut.container.override("csrf_protector") do
#         CsrfProtector.new
#       end
#       
#       # ...
#
class Brut::FrontEnd::CsrfProtector

  # Return true if the request should be allowed without a CSRF token. This implementation allows webhooks and paths that Brut owns explicitly
  def allowed?(env)
    env["brut.webhook"]  || env["brut.owned_path"] 
  end
end
