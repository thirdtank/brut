require "delegate"

# A delegator to a Nokogiri Node that provides convienience methods
# for navigating the DOM inside a test.
class Brut::SpecSupport::EnhancedNode < SimpleDelegator
  include RSpec::Matchers

  # Return the only Nokogiri::XML::Node for the given CSS selector, if it exists.
  # If the selector matches more than one element, the test fails. If the selector 
  # matches one element, it is returned, and nil is returned if no elements match.
  def e(css_selector)
    element = css(css_selector)
    if (element.kind_of?(Nokogiri::XML::NodeSet))
      expect(element.length).to be < 2
      first_element = element.first
      if first_element
        return Brut::SpecSupport::EnhancedNode.new(first_element)
      else
        return nil
      end
    else
      expect([Nokogiri::XML::Node, Nokogiri::XML::Element]).to include(element.class)
      return Brut::SpecSupport::EnhancedNode.new(element)
    end
  end

  # Assert exactly one Nokogiri::XML::Node exists for the given CSS selector and return it. If there is not
  # exactly one matching node, the test fails.
  def e!(css_selector)
    element = css(css_selector)
    if (element.kind_of?(Nokogiri::XML::NodeSet))
      expect(element.length).to eq(1),"#{css_selector} matched #{element.length} elements, not exactly 1:\n\n#{to_html}"
      return Brut::SpecSupport::EnhancedNode.new(element.first)
    else
      expect([Nokogiri::XML::Node, Nokogiri::XML::Element]).to include(element.class)
      return Brut::SpecSupport::EnhancedNode.new(element)
    end
  end

  # Return ths first Nokogiri::XML::Node for the given CSS selector. If there are no
  # matching nodes, the test fails.
  def first!(css_selector)
    element = css(css_selector)
    if (element.kind_of?(Nokogiri::XML::NodeSet))
      expect(element.first).not_to eq(nil), "No elements matching #{css_selector}"
      return Brut::SpecSupport::EnhancedNode.new(element.first)
    else
      expect([Nokogiri::XML::Node, Nokogiri::XML::Element]).to include(element.class)
      return Brut::SpecSupport::EnhancedNode.new(element)
    end
  end

end
