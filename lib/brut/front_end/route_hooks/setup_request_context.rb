class Brut::FrontEnd::RouteHooks::SetupRequestContext < Brut::FrontEnd::RouteHook
  def before(app_session:,request:,env:)
    flash = app_session.flash
    app_session[:_flash] ||= flash
    Thread.current.thread_variable_set(
      :request_context,
      Brut::FrontEnd::RequestContext.new(env:,session:app_session,flash:,xhr: request.xhr?,body: request.body)
    )
    continue
  end
end
