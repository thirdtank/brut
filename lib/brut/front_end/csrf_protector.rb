# Base for custom logic around CSRF protection.  Brut configures `Rack::Protection::AuthenticityToken` for all requests, and
# this happens early in the request.  The idea is that no real POST should be missing a CSRF token.  That said, there are times
# when it must be skipped, such as for webhooks.  In that case, you can extend this class and configure it via
# `Brut.container.override("csrf_protector", YourCustomCsrfProtector.new)` in your `App` class' initializer.
#
# @example
#   class CsrfProtector < Brut::FrontEnd::CsrfProtector
#     def allowed?(env)
#       !!env["PATH_INFO"].to_s.match?(/^\/webhooks\//)
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

  # Return true if the request should be allowed without a CSRF token. This implementation returns false.
  def allowed?(env)
    false
  end
end
