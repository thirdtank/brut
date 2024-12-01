class Brut::FrontEnd::RouteHooks::SetupRequestContext < Brut::FrontEnd::RouteHook
  def before(session:,request:,env:)
    flash = session.flash
    session[:_flash] ||= flash
    Thread.current.thread_variable_set(
      :request_context,
      Brut::FrontEnd::RequestContext.new(env:,session:session,flash:,xhr: request.xhr?,body: request.body)
    )
    continue
  end
end
