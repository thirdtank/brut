require "delegate"

class Brut::SpecSupport::EnhancedNode < SimpleDelegator
  include RSpec::Matchers

  # Return the Nokogiri::XML::Node for the given CSS selector.
  # If the selector matches more than one element, the test fails. If the selector 
  # matches one element, it is returned, and nil is returned if no elements match.
  def e(css_selector)
    element = css(css_selector)
    if (element.kind_of?(Nokogiri::XML::NodeSet))
      expect(element.length).to be < 2
      return element.first
    else
      expect([Nokogiri::XML::Node, Nokogiri::XML::Element]).to include(element.class)
      return element
    end
  end

  # Retun the Nokogiri::XML::Node for the given CSS selector. If there is not
  # exactly one matching node, the test fails.
  def e!(css_selector)
    element = css(css_selector)
    if (element.kind_of?(Nokogiri::XML::NodeSet))
      expect(element.length).to eq(1),"#{css_selector} matched #{element.length} elements, not exactly 1:\n\n#{to_html}"
      return element.first
    else
      expect([Nokogiri::XML::Node, Nokogiri::XML::Element]).to include(element.class)
      return element
    end
  end

end
