# Manages the value for the HTTP
# [Accept-Language](https://developer.mozilla.org/en-US/docs/Web/HTTP/Reference/Headers/Accept-Language)
# header. Generally, you would not interact with this class directly, however it is used
# by Brut to make a guess as to which Locale a browser is reporting.
class Brut::I18n::HTTPAcceptLanguage
  # A locale with the weight (value for q=) it was given in the Accept-Language header
  WeightedLocale = Data.define(:locale, :q) do
    # Returns the primary locale for whatever locale
    # this is holding.  For example, the primary locale 
    # of "en-US" is "en".
    def primary_locale = self.locale.gsub(/\-.*$/,"")

    # True if this locale is a primary locale
    def primary? = self.primary_locale == self.locale

    # Return a new WeightedLocale that is the primary locale.
    def primary_only
      self.class.new(locale: self.primary_locale, q: self.q)
    end

    def ==(other)
      self.locale == other.locale
    end
  end

  # Parse the value stored in the session.
  #
  # @param [String] session_value the value stored in the session.
  # @return [Brut::I18n::HTTPAcceptLanguage] a usable object. If the provided value
  #         is blank, #{Brut::I18n::HTTPAcceptLanguage::AlwaysEnglish} is returned.
  def self.from_session(session_value)
    values = session_value.to_s.split(/,/).map { |value|
      locale,q = value.split(/;/)
      WeightedLocale.new(locale:,q:)
    }
    if values.any?
      self.new(values)
    else
      AlwaysEnglish.new
    end
  end

  # Parse the value provided by the browser via 
  # {Brut::FrontEnd::Handlers::LocaleDetectionHandler} via
  # the `brut-locale-detection` custom element (which
  # uses `Intl.DateTimeFormat().resolvedOptions()` to determine
  # the locale).
  #
  # Because this value is not in the same format as the Accept-Language
  # header, it's `q` is assumed to be 1.
  #
  # @param [String] value the value provided by the brower.
  #
  # @return [Brut::I18n::HTTPAcceptLanguage] a usable object. If the provided value
  #         is blank, #{Brut::I18n::HTTPAcceptLanguage::AlwaysEnglish} is returned.
  def self.from_browser(value)
    value = value.to_s.strip
    if value == ""
      AlwaysEnglish.new
    else
      self.new([ WeightedLocale.new(locale: value, q: 1) ])
    end
  end

  # Parse from the HTTP Accept-Language header.
  #
  # @return [Brut::I18n::HTTPAcceptLanguage] a usable object. If the provided value
  #         is blank, #{Brut::I18n::HTTPAcceptLanguage::AlwaysEnglish} is returned.
  def self.from_header(header_value)
    header_value = header_value.to_s.strip
    if header_value == "*" || header_value == ""
      AlwaysEnglish.new
    else
      values = header_value.split(/,/).map(&:strip).map { |language|
        locale,q = language.split(/;\s*q\s*=\s*/,2)
        WeightedLocale.new(locale: locale,q: q.nil? ? 1 : q.to_f)
      }
      if values.any?
        self.new(values)
      else
        AlwaysEnglish.new
      end
    end
  end

  # Ordered list of locales, from highest-weighted to lowest.
  attr_reader :weighted_locales
  # @param [Array<Brut::I18n::HTTPAcceptLanguage::WeightedLocale>] weighted_locales locales to use. They do not
  #        need to be ordered
  def initialize(weighted_locales)
    @weighted_locales = weighted_locales.sort_by(&:q).reverse
  end

  # True if the values inside this object represent known locales, and not a guess based on missing information.
  # In general, this returns true if the values came from the Accept-Language header, or from the browser.
  def known? = true

  # Serialize for storage in the session
  #
  # @return [String] a string that can be stored in the session and later deserialized via {.from_session}.
  def for_session = @weighted_locales.map { |weighted_locale| "#{weighted_locale.locale};#{weighted_locale.q}" }.join(",")
  def to_s = self.for_session

  # A subclass that represents the use of English and only English.  This is
  # used when attempts to determine the locale fail.  Instances of this class
  # are considered "unknown" ({#known?} returns false), which allows Brut
  # to replace this with a known value later on.
  class AlwaysEnglish < Brut::I18n::HTTPAcceptLanguage
    def initialize
      super([ WeightedLocale.new(locale: "en", q: 1) ])
    end
    def known? = false
  end

end
