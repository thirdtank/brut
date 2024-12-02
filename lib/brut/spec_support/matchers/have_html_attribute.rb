RSpec::Matchers.define :have_html_attribute do |attribute|
  if attribute.kind_of?(Hash)
    if attribute.keys.length != 1
      raise "have_html_attribute requires a single hash with a single key, or a single symbol/string. Received #{attribute.keys.length} keys: '#{attribute.keys.map(&:to_s).join(", ")}'"
    end
  elsif !attribute.kind_of?(Symbol) && !attribute.kind_of?(String)
    raise "have_html_attribute requires a single hash with a single key, or a single symbol/string. Received a #{attribute.class}"
  end

  match do |result|
    Brut::SpecSupport::Matchers::HaveHTMLAttribute.new(result,attribute).matches?
  end

  failure_message do |result|
    Brut::SpecSupport::Matchers::HaveHTMLAttribute.new(result,attribute).error
  end

  failure_message_when_negated do |result|
    if attribute.kind_of?(Hash)
      "Found attribute '#{attribute.keys.first}' with value '#{attribute.values.first}'"
    else
      "Found attribute '#{attribute}' when not expecting it #{result.to_html}"
    end
  end
end

class Brut::SpecSupport::Matchers::HaveHTMLAttribute

  attr_reader :error

  def initialize(result, attribute)
    @error = nil
    if result.kind_of?(Nokogiri::XML::NodeSet)
      if result.length > 1
        @error = "Received #{result.length} matching nodes, when only one should've been returned"
      elsif result.length == 0
        @error = "Received no matching nodes to examine"
      else
        result = result.first
      end
    else
      object_to_check = if result.kind_of?(SimpleDelegator)
                          result.__getobj__
                        else
                          result
                        end
      if !object_to_check.kind_of?(Nokogiri::XML::Element)
        @error = "Received a #{result.class} instead of a NodeSet or Element, as could be returned by `.css(...)`"
      end
    end
    if !@error
      if attribute.kind_of?(Hash)
        attribute_name  = attribute.keys.first.to_s
        attribute_value = attribute.values.first.to_s
      else
        attribute_name = attribute.to_s
        attribute_value = :any
      end

      nokogiri_attribute = result.attribute(attribute_name)
      if nokogiri_attribute
        if attribute_value != :any
          found_value = result.attribute(attribute_name).value

          if found_value != attribute_value
            @error = "Value for '#{attribute_name}' was '#{found_value}'. Expected '#{attribute_value}'"
          end
        end
      else
        @error = "Did not find attribute '#{attribute_name}' on element.  Found: #{result.attributes.keys.join(", ")}"
      end
    end
  end

  def matches? = @error.nil?
end
