require_relative "flash_support"
require_relative "session_support"
require_relative "clock_support"
require_relative "enhanced_node"

# Convienience methods for writing tests of components or pages.
module Brut::SpecSupport::ComponentSupport
  include Brut::SpecSupport::FlashSupport
  include Brut::SpecSupport::SessionSupport
  include Brut::SpecSupport::ClockSupport
  include Brut::I18n::ForBackEnd # XXX: Maybe need a "ForSpecs"?

  # Render a component or page into its text representation.  This mimics what happens when Brut renders
  # the page or component.  Note that pages don't always return Strings, for example if `before_render`
  # returns a redirect.
  #
  # When testing a component, call {#render_and_parse} instead of this. When testing a page that will
  # always render HTML, again call {#render_and_parse}.
  #
  # When using this, there are some matchers that can help assert what the page has done:
  #
  # * `have_redirected_to` to check that the page redirected elsewhere, instead of rendering.
  # * `have_returned_http_status` to check that the page returned an HTTP status instead of rendering.
  def render(component,&block)
    if component.kind_of?(Brut::FrontEnd::Page)
      if !block.nil?
        raise "pages do not accept blocks - do not pass one to render_and_parse"
      end
      component.handle!
    else
      if block.nil?
        component.call
      else
        component.call do
          component.raw(component.safe(block.()))
        end
      end
    end
  end

  # Render a component or page and parse it into a Nokogiri Node for examination.  There are several matchers
  # you can use with the return value of this method:
  #
  # * `have_html_attribute` to check if a node has a value for an HTML attribute.
  # * `have_i18n_string` to check if the text of a node is exactly an i18n string you have set up.
  # * `have_link_to` to check that a node contains a link to a page or page routing
  #
  #
  # @example
  #
  #   result = render_and_parse(HeaderComponent.new(title: "Hello!")
  #   expect(result.e!("h1").text).to eq("Hello!")
  #
  # @example Using context
  #   result = render_and_parse(TableRow.new([ "one", "two" ]), context: "tbody")
  #
  # @param [Brut::FrontEnd::Component] component the component instance you wish to render. This should be set up to simulate the test
  # you are running.
  # @yield if the component requires or accepts a yielded block, this is how you do that in the test.
  # @return [Brut::SpecSupport::EnhancedNode] a wrapper around a Nokogiri node to provide convienience methods.
  def render_and_parse(component,&block)
    rendered_text = render(component,&block)
    if !rendered_text.kind_of?(String)
      if rendered_text.kind_of?(URI::Generic)
        raise "#{component.class} redirected to #{rendered_text} instead of rendering"
      else
        raise "#{component.class} returned a #{rendered_text.class} - you should not attempt to parse this.  Instead, call render(component)"
      end
    end
    nokogiri_node = Nokogiri::HTML5(rendered_text)
    if !component.kind_of?(Brut::FrontEnd::Page)
      nokogiri_node = Nokogiri::HTML5.fragment(rendered_text.to_s.chomp, max_errors: 100, context: "template")
      if nokogiri_node.errors.any?
        raise "#{component.class} render invalid HTML:\n\n#{rendered_text}\n\nErrors: #{nokogiri_node.errors.join(", ")}"
      end

      non_blank_text_elements = nokogiri_node.children.select { |element|
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
    if nokogiri_node
      Brut::SpecSupport::EnhancedNode.new(nokogiri_node)
    else
      nil
    end
  end

  # @!visibility private
  def routing_for(klass,**args)
    Brut.container.routing.path(klass,**args)
  end
end
