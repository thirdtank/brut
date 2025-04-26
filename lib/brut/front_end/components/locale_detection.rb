# Produces the `<brut-locale-detection>` custom element, with attributes set as appropriate based on the server's
# understanding of the current session's locale.
#
# The `<brut-locale-detection>` element exists to send a JSON payload back to the server
# (handled by {Brut::FrontEnd::Handlers::LocaleDetectionHandler}), with information about the browser's time zone and locale.
#
# This element doesn't need to do this if the server has this information.  This component handles creating the right HTML to either
# ask the browser to send it, or not.
class Brut::FrontEnd::Components::LocaleDetection < Brut::FrontEnd::Component2
  def initialize(session:)
    @timezone = session.timezone_from_browser
    @locale   = session.http_accept_language.known? ? session.http_accept_language.weighted_locales.first&.locale : nil
    @url      = Brut::FrontEnd::Handlers::LocaleDetectionHandler.routing
  end

  def view_template
    attributes = {
      "url" => @url.to_s,
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

    brut_locale_detection(**attributes)
  end
end
