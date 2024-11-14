# Produces `<brut-locale-detection>`
class Brut::FrontEnd::Components::LocaleDetection < Brut::FrontEnd::Component
  def initialize(session:)
    @timezone = session.timezone_from_browser
    @locale   = session.http_accept_language.known? ? session.http_accept_language.weighted_locales.first&.locale : nil
    @url      = Brut::FrontEnd::Handlers::LocaleDetectionHandler.routing
  end

  def render
    attributes = {
      "url" => @url,
    }
    if @timezone
      attributes["timezone-from-server"] = @timezone.name
    end
    if @locale
      attributes["locale-from-server"] = @locale
    end
    if !Brut.container.project_env.production?
      attributes["show-warnings"] = true
    end

    html_tag("brut-locale-detection",**attributes)
  end
end
