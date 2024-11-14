require_relative "flash_support"
module Brut::SpecSupport::ComponentSupport
  include Brut::SpecSupport::FlashSupport
  include Brut::I18n::ForHTML

  def render_and_parse(component,&block)
    if component.kind_of?(Brut::FrontEnd::Page)
      if !block.nil?
        raise "pages do not accept blocks - do not pass one to render_and_parse"
      end
      result = component.handle!
      case result
      in String => html
        Nokogiri::HTML5(html)
      else
        result
      end
    else
      component.yielded_block = block
      rendered_text = component.render
      document = Nokogiri::HTML5(rendered_text)
      component_html = document.css("body")
      if component_html
        non_blank_text_elements = component_html.children.select { |element|
          if element.kind_of?(Nokogiri::XML::Text) && element.text.to_s.strip == ""
            false
          else
            true
          end
        }
        if non_blank_text_elements.size == 1
          non_blank_text_elements[0]
        else
          raise "#{component.class} rendered #{non_blank_text_elements.size} elements other than blank text:\n\n#{non_blank_text_elements.map(&:name)}. Components should render a single element:\n#{rendered_text}"
        end
      else
        raise "#{component.class} did not render HTML properly: #{rendered_text}"
      end
    end
  end

  def routing_for(klass,**args)
    Brut.container.routing.uri(klass,**args)
  end

  def escape_html(...)
    Brut::FrontEnd::Templates::EscapableFilter.escape_html(...)
  end
end
