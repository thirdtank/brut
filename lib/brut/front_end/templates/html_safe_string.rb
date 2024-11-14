# A wrapper around a string to indicate it is HTML-safe and
# can be rendered directly without escaping.
class Brut::FrontEnd::Templates::HTMLSafeString
  module Refinement
    refine String do
      def html_safe! = Brut::FrontEnd::Templates::HTMLSafeString.from_string(self)
      def html_safe? = false
    end
  end
  attr_reader :string
  def initialize(string)
    @string = string
  end

  # Wrap a string in an HTMLSafeString if needed.
  def self.from_string(string_or_html_safe_string)
    if string_or_html_safe_string.kind_of?(self)
      string_or_html_safe_string
    else
      self.new(string_or_html_safe_string)
    end
  end

  # This must be convertible to a string
  def to_s       = @string
  def to_str     = @string
  def html_safe! = self
  def html_safe? = true
  def capitalize = self.class.new(@string.capitalize)
  def downcase   = self.class.new(@string.downcase)
  def upcase     = self.class.new(@string.upcase)

  def +(other)
    if other.html_safe?
      self.class.new(@string + other.to_s)
    else
      @string + other.to_s
    end
  end
end
