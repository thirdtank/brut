# Detects the user's locale from the `Accept-Language` header and, if one of the locales has been set up in this app, configured
# Ruby's `I18n` to use it.  This will also store the value in the session via {Brut::FrontEnd::Session#http_accept_language=}.
#
# @see https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Accept-Language
class Brut::FrontEnd::RouteHooks::LocaleDetection < Brut::FrontEnd::RouteHook
  def before(session:,env:,request:)
    session.timezone_from_browser = request.cookies["brut.timezone"]
    session.http_accept_language = Brut::I18n::HTTPAcceptLanguage.from_header(env["HTTP_ACCEPT_LANGUAGE"])
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
      Brut.container.instrumentation.add_attributes(prefix: "brut.locale-detection", best_locale:)
      ::I18n.locale = best_locale
    else
      Brut.container.instrumentation.add_attributes(prefix: "brut.locale-detection", best_locale: false)
      ::I18n.locale = I18n.default_locale
    end
    continue
  end
  def after(response:)
    vary = VaryHeader.new(response.headers["Vary"])
    vary << "cookie"
    vary << "accept-language"
    response.headers["Vary"] = vary.to_s
    response.headers["Content-Language"] = ::I18n.locale.to_s
    continue
  end

private

  class VaryHeader
    def initialize(initial_header_value)
      @values = Set.new
      Array(initial_header_value).map { it.split(/,/) }.flatten(1).each do |value|
        self.<< value
      end
    end

    def <<(value)
      if !@values.include?("*")
        @values.add(value.downcase.strip)
      end
    end

    def to_s
      @values.to_a.reject(&:empty?).uniq.sort.join(",")
    end
  end
end
