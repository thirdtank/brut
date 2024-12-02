require_relative "flash_support"
require_relative "enhanced_node"
module Brut::SpecSupport::ComponentSupport
  include Brut::SpecSupport::FlashSupport
  include Brut::I18n::ForHTML

  def render(component,&block)
    if component.kind_of?(Brut::FrontEnd::Page)
      if !block.nil?
        raise "pages do not accept blocks - do not pass one to render_and_parse"
      end
      component.handle!
    else
      component.yielded_block = block
      component.render
    end
  end

  def render_and_parse(component,&block)
    rendered_text = render(component,&block)
    if !rendered_text.kind_of?(String) && !rendered_text.kind_of?(Brut::FrontEnd::Templates::HTMLSafeString)
      raise "#{component.class} returned a #{rendered_text.class} - you should not attempt to parse this.  Instead, call render(component)"
    end
    nokogiri_node = Nokogiri::HTML5(rendered_text)
    if !component.kind_of?(Brut::FrontEnd::Page)
      component_html = nokogiri_node.css("body")
      if !component_html
        raise "#{component.class} did not render HTML properly: #{rendered_text}"
      end

      non_blank_text_elements = component_html.children.select { |element|
        is_text  = element.kind_of?(Nokogiri::XML::Text)
        is_blank = element.text.to_s.strip == ""

        is_blank_text = is_text && is_blank

        !is_blank_text
      }

      if non_blank_text_elements.size != 1
        raise "#{component.class} rendered #{non_blank_text_elements.size} elements other than blank text:\n\n#{non_blank_text_elements.map(&:name)}. Components should render a single element:\n#{rendered_text}"
      end
      nokogiri_node = non_blank_text_elements[0]
    end
    Brut::SpecSupport::EnhancedNode.new(nokogiri_node)
  end

  def routing_for(klass,**args)
    Brut.container.routing.uri(klass,**args)
  end

  def escape_html(...)
    Brut::FrontEnd::Templates::EscapableFilter.escape_html(...)
  end
end
