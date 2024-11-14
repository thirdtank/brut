class Brut::FrontEnd::RouteHooks::AgeFlash < Brut::FrontEnd::RouteHook
  def after(app_session:,request_context:)
    flash = request_context[:flash]
    flash.age!
    app_session.flash = flash
    continue
  end
end
