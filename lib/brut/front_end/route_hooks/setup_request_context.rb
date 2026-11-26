# Sets up the {Brut::FrontEnd::RequestContext} based on the contents of the session.
# This is so that downstream handlers and hooks can have access to richer data than the hashes
# and strings provided by Rack.
class Brut::FrontEnd::RouteHooks::SetupRequestContext < Brut::FrontEnd::RouteHook
  def before(session:,request:,env:)
    host_uri = URI.parse("#{request.scheme}://#{request.host}:#{request.port}")
    Brut::FrontEnd::RequestContext.current = Brut::FrontEnd::RequestContext.new(
      env:,
      session:session,
      flash: session.flash,
      xhr: request.xhr?,
      body: request.body,
      host: host_uri
    )

    continue
  end
end
