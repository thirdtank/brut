# Manages the value for the HTTP
# [Accept-Language](https://developer.mozilla.org/en-US/docs/Web/HTTP/Reference/Headers/Accept-Language)
# header. Generally, you would not interact with this class directly, however it is used
# by Brut to make a guess as to which Locale a browser is reporting.
class Brut::I18n::HTTPAcceptLanguage
  # A locale with the weight (value for q=) it was given in the Accept-Language header
  WeightedLocale = Data.define(:raw_locale, :q) do

    # True if this locale was created with an invalid or unknown raw_locale
    def invalid? = self.tag.nil?

    # The RFC 4646 "tag" for this locale, or nil if it's not valid
    # @return [I18n::Locale::Tag::Rfc4646|nil] tag based on the raw_locale, or nil if it's not valid.
    def tag = I18n::Locale::Tag::Rfc4646.tag(self.raw_locale)

    # The locale or nil if raw_locale was not valid
    # @return [String|nil] String containing the full locale e.g. en-GB or nil if raw_locale was invalid.
    def locale = self.tag&.to_s

    # Returns the primary locale for whatever locale
    # this is holding.  For example, the primary locale 
    # of "en-US" is "en".
    def primary_locale = self.tag&.language

    # Return a new WeightedLocale that is the primary locale.
    def primary_only
      self.class.new(raw_locale: self.primary_locale, q: self.q)
    end

    def ==(other)
      self.tag == other.tag
    end
  end

  # Parse the value stored in the session.
  #
  # @param [String] session_value the value stored in the session.
  # @return [Brut::I18n::HTTPAcceptLanguage] a usable object. If the provided value
  #         is blank, #{Brut::I18n::HTTPAcceptLanguage::AlwaysEnglish} is returned.
  def self.from_session(session_value)
    values = session_value.to_s.split(/,/).map { |value|
      raw_locale,q = value.split(/;/)
      WeightedLocale.new(raw_locale:,q:)
    }.reject(&:invalid?)
    if values.any?
      self.new(values)
    else
      AlwaysEnglish.new
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
        raw_locale,q = language.split(/;\s*q\s*=\s*/,2)
        WeightedLocale.new(raw_locale: ,q: q.nil? ? 1 : q.to_f)
      }.reject(&:invalid?)
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

  # Serialize for storage in the session
  #
  # @return [String] a string that can be stored in the session and later deserialized via {.from_session}.
  def for_session = @weighted_locales.map { |weighted_locale| "#{weighted_locale.locale};#{weighted_locale.q}" }.join(",")
  def to_s = self.for_session

  # A subclass that represents the use of English and only English.  This is
  # used when attempts to determine the locale fail.
  class AlwaysEnglish < Brut::I18n::HTTPAcceptLanguage
    def initialize
      super([ WeightedLocale.new(raw_locale: "en", q: 1) ])
    end
  end

end
