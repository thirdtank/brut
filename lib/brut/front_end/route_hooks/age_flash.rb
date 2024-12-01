class Brut::FrontEnd::RouteHooks::AgeFlash < Brut::FrontEnd::RouteHook
  def after(session:,request_context:)
    flash = request_context[:flash]
    flash.age!
    session.flash = flash
    continue
  end
end
