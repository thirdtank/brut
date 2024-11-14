class Brut::I18n::HTTPAcceptLanguage
  WeightedLocale = Data.define(:locale, :q) do
    def primary_locale = self.locale.gsub(/\-.*$/,"")
    def primary? = self.primary_locale == self.locale

    def primary_only
      self.class.new(locale: self.primary_locale, q: self.q)
    end

    def ==(other)
      self.locale == other.locale
    end
  end

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

  def self.from_browser(value)
    value = value.to_s.strip
    if value == ""
      AlwaysEnglish.new
    else
      self.new([ WeightedLocale.new(locale: value, q: 1) ])
    end
  end

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

  attr_reader :weighted_locales
  def initialize(weighted_locales)
    @weighted_locales = weighted_locales.sort_by(&:q).reverse
  end
  def known? = true
  def for_session = @weighted_locales.map { |weighted_locale| "#{weighted_locale.locale};#{weighted_locale.q}" }.join(",")
  def to_s = self.for_session

  class AlwaysEnglish < Brut::I18n::HTTPAcceptLanguage
    def initialize
      super([ WeightedLocale.new(locale: "en", q: 1) ])
    end
    def known? = false
  end

end
