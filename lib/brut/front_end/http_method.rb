require "phlex"

# Wrapper around an HTTP Method, ensuring it contains only a valid value.
class Brut::FrontEnd::HttpMethod
  include Phlex::SGML::SafeObject

  # Create an HTTP method from a string.
  #
  # @param [String|Symbol] string a string containing an HTTP method name. Case insensitive, and can be a symbol.
  #
  # @raise [ArgumentError] if the passed `string` is not a valid HTTP method
  def initialize(string)
    normalized = string.to_s.downcase.to_sym
    if !self.class.method_names.include?(normalized)
      raise ArgumentError,"'#{string}' is not a known HTTP method"
    end
    @method = normalized
  end

  # @return [String] the method name, normalized to all lower case, as a string
  def to_s = @method.to_s
  # @return [Symbol] the method name, normalized to all lower case, as a symbol
  def to_sym = @method.to_sym
  alias to_str to_s

  # @return [true|false] True if the other object is the same class as this and has the same string representation
  def ==(other)
    self.class.name == other.class.name && self.to_s == other.to_s
  end

  # @return [true|false] true if this is a GET
  def get?  = self.to_sym == :get
  # @return [true|false] true if this is a POST
  def post? = self.to_sym == :post

private

  def self.method_names = [
    :connect,
    :delete,
    :get,
    :head,
    :options,
    :patch,
    :post,
    :put,
    :trace,
  ].freeze
end
