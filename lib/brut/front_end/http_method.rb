class Brut::FrontEnd::HttpMethod
  def initialize(string)
    normalized = string.to_s.downcase.to_sym
    if !self.class.method_names.include?(normalized)
      raise ArgumentError,"'#{string}' is not a known HTTP method"
    end
    @method = normalized
  end

  def to_s = @method.to_s
  def to_sym = @method.to_sym
  alias to_str to_s

  def ==(other)
    self.class.name == other.class.name && self.to_s == other.to_s
  end

  def get? = self.to_sym == :get

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
