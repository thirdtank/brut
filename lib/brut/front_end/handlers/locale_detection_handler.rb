class Brut::FrontEnd::Handlers::LocaleDetectionHandler < Brut::FrontEnd::Handler
  def handle(body:,session:)
    begin
      parsed = JSON.parse(body.read)
      SemanticLogger["brut:__brut/locale"].info("Got #{parsed.class}/#{parsed}")
      if parsed.kind_of?(Hash)
        locale   = parsed["locale"]
        timezone = parsed["timeZone"]

        session.timezone_from_browser = timezone
        if !session.http_accept_language.known?
          session.http_accept_language = Brut::I18n::HTTPAcceptLanguage.from_browser(locale)
        end
      else
        SemanticLogger["brut:__brut/locale"].warn("Got a #{parsed.class} from /__brut/locale instead of a hash")
      end
    rescue => ex
      SemanticLogger["brut:__brut/locale"].warn("Got #{ex} from /__brut/locale instead of a parseable JSON object")
    end
    http_status(200)
  end
end
