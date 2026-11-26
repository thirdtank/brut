# A wrapper around a hash of attributes design to be used
# when generating HTML form inputs.  This works somewhat backward from a normal
# Hash in that the initial values serve as the preferred values the hash
# should use, while default/fallback values are set explicitly
# inside a `with_defaults` block.
class Brut::FrontEnd::Forms::HtmlAttributes

  # Create the HTML attributes based on a set of initial attributes and a map
  # of disallowed attributes.
  # @param [Brut::FrontEnd::Forms::Input] input The input that these
  #        attributes are for. This is used to set the name attribute, which cannot
  #        be overridden.
  # @param [Hash] initial_attributes hash of attributes names/values that will
  #        be in the ultimate set of attributes.  These will override
  #        any default set with {#with_defaults}. The keys will be downcased.
  # @param [Hash] forbidden_attributes hash of attribute names to explanations
  #        for why that attribute is not allowed.  These names are downcased, and
  #        if any appear in `initial_attributes`, an `ArgumentError` is raised.
  def initialize(input:, initial_attributes: {}, forbidden_attributes: {})
    @html_attributes = normalize_keys(initial_attributes).merge({
      name: input.array? ? "#{input.name}[]" : input.name,
    })

    error_messages = normalize_keys(forbidden_attributes).map { |attribute, explanation|
      if @html_attributes.key?(attribute)
        explanation
      else
        nil
      end
    }.compact
    if error_messages.any?
      raise ArgumentError, error_messages.join(", ")
    end
  end

  # Yield a block which is given a hash where you can 
  # set default values for any attributes not present in
  # `initial_attributes`.
  def with_defaults(&block)
    default_html_attributes = {}
    block.(default_html_attributes)
    @html_attributes = normalize_keys(default_html_attributes).merge(@html_attributes)
    self
  end

  def [](key) = @html_attributes[normalize_key(key)]

  def to_h = @html_attributes
  alias_method :to_hash, :to_h  

private

  def normalize_keys(hash)
    hash.map { |key,value|
      [
        normalize_key(key),
        value,
      ]
    }.to_h
  end

  def normalize_key(key) = key.to_s.downcase.to_sym

end
