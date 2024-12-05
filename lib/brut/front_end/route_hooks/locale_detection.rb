# Detects the user's locale from the `Accept-Language` header and, if one of the locales has been set up in this app, configured
# Ruby's `I18n` to use it.  This will also store the value in the session via {Brut::FrontEnd::Session#http_accept_language=}.
#
# @see https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Accept-Language
class Brut::FrontEnd::RouteHooks::LocaleDetection < Brut::FrontEnd::RouteHook
  def before(session:,env:)
    http_accept_language = Brut::I18n::HTTPAcceptLanguage.from_header(env["HTTP_ACCEPT_LANGUAGE"])
    if !session.http_accept_language.known?
      session.http_accept_language = http_accept_language
    end
    best_locale = nil
    session.http_accept_language.weighted_locales.each do |weighted_locale|
      if ::I18n.available_locales.include?(weighted_locale.locale.to_sym)
        best_locale = weighted_locale.locale.to_sym
        break
      elsif ::I18n.available_locales.include?(weighted_locale.primary_only.locale.to_sym)
        best_locale = weighted_locale.primary_only.locale.to_sym
        break
      end
    end
    if best_locale
      ::I18n.locale = best_locale
    else
      SemanticLogger["Brut"].warn("None of the user's locales are available: #{session.http_accept_language}")
    end
    continue
  end
end
