# A wrapper around a string to indicate it is HTML-safe and
# can be rendered directly without escaping. This was done to avoid adding methods on `String` and the internal state
# required to make something like `"foo".html_safe!` work.
class Brut::FrontEnd::Templates::HTMLSafeString
  # This can be used via `using` to add `html_safe!` and `html_safe?` method to `String` when they might be more convienient
  # than using {Brut::FrontEnd::Templates::HTMLSafeString} directly.
  module Refinement
    refine String do
      def html_safe! = Brut::FrontEnd::Templates::HTMLSafeString.from_string(self)
      def html_safe? = false
    end
  end
  using Refinement

  # @return [String] the underlying string being wrapped
  attr_reader :string

  # Create an HTML safe string based on the parameter. It's recommended to use {.from_string} instead.
  #
  # @param [String] string A string that is considered safe to put directly into a web page without escaping.
  def initialize(string)
    @string = string
  end

  # Creates an HTML Safe string based on the parameter, properly handling if a HTML safe string is being passed.
  #
  # @param [String|Brut::FrontEnd::Templates::HTMLSafeString] string_or_html_safe_string the value to turn into an HTML safe string.
  #
  # @return [Brut::FrontEnd::Templates::HTMLSafeString] if `string_or_html_safe_string` is already HTML safe, returns it. Otherwise,
  # wraps the string as HTML safe.
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
  # Matches the protocol in {Brut::FrontEnd::Templates::HTMLSafeString::Refinement}
  # @return [Brut::FrontEnd::Templates::HTMLSafeString] self
  def html_safe! = self
  # Matches the protocol in {Brut::FrontEnd::Templates::HTMLSafeString::Refinement}
  # @return [true|false] true
  def html_safe? = true

  # Return a new instance that has called `capitalize` on the underlying string
  def capitalize = self.class.new(@string.capitalize)
  # Return a new instance that has called `downcase` on the underlying string
  def downcase   = self.class.new(@string.downcase)
  # Return a new instance that has called `upcase` on the underlying string
  def upcase     = self.class.new(@string.upcase)

  # Returns the concatenation of two strings. If the other is HTML safe, then this returns an HTML safe string.
  # If the other is not, this returns a normal unsafe string.
  #
  # @param [String|Brut::FrontEnd::Templates::HTMLSafeString] other
  # @return [String|Brut::FrontEnd::Templates::HTMLSafeString] A safe or unsafe string, depending on what was passed.
  def +(other)
    if other.html_safe?
      self.class.new(@string + other.to_s)
    else
      @string + other.to_s
    end
  end
end
