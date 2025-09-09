# A Page backs a web page, which handles rendering everything in a browser window when a URL is requested.
# Technically, a page is identical to a {Brut::FrontEnd::Component}, except that a page has a layout.
# A {Brut::FrontEnd::Layout} is common HTML that surrounds your page's HTML.
# Your page is a Phlex component, but instead of implementing `view_template`, you
# implement {#page_template} to ensure the layout is used.
#
# To create a page, after defining a route, subclass this class (or, more likely, your app's `AppPage`) and
# provide an initializer that accepts keyword arguments.  The names of these arguments will be used to locate the
# values that Brut will pass in when creating your page object.
#
# Consult Brut's documentation on keyword injection to know what values you may use and how values are located.
#
# @see Brut::FrontEnd::Component
# @see Brut::FrontEnd::Layout
class Brut::FrontEnd::Page < Brut::FrontEnd::Component
  include Brut::FrontEnd::HandlingResults

  # Returns the name of the layout for this page.  This string is used to find a class named
  # `«camelized-layout»Layout` in your app.  The default value is "default", meaning that the class
  # `DefaultLayout` will be used.
  #
  # Note that the layout can be dynamic. It is requested when {#page_template} is called, so you can override this
  # method and use any ivar set in your constructor to change what layout is used.
  #
  # If your page does not need a layout, you have two options:
  #
  # * Create your own blank layout named, e.g. `BlankLayout` and have this method return `"blank"`.
  # * Implement `view_template` instead of `page_template`, thus overriding this class' implementation that uses
  #   layouts.
  #
  # @return [String] The name of the layout. May not be `nil`.
  def layout = "default"

  # Called after the page is created, but before {#page_template} is called.  This allows you to do any pre-flight checks and potentially
  # redirect the user or produce an error.
  #
  # @return [URI|Brut::FrontEnd::HttpStatus|Object] If you return a `URI` (mostly likely by returning the result of calling {Brut::FrontEnd::HandlingResults#redirect_to}), the user is redirected and no HTML is generated. If you return a {Brut::FrontEnd::HttpStatus} (mostly likely by returning the result of calling {Brut::FrontEnd::HandlingResults#http_status}), HTML generation is skipped and that status is returned with no content.  If anything else is returned, HTML is generated normal.
  def before_generate = nil

  # Core method of this class. Do not override. This handles the use of {#before_generate} and is what Brut
  # calls to possibly render the page.
  def handle!
    Brut.container.instrumentation.span(self.class.name + "#handle!") do |span|
      case before_generate
      in URI => uri
        uri
      in Brut::FrontEnd::HttpStatus => http_status
        http_status
      else
        Brut.container.instrumentation.span(self.class.name + "#handle") do |span|
          self.call
        end
      end
    end
  end

  # Override this method to produce your page's HTML. You are intended to call Phlex
  # methods here. Anything you can do inside the Phlex-standard `view_template` method, you can 
  # do here. The only difference is that this will all be rendered in the context of your configured
  # {#layout}.
  def page_template = abstract_method!

  # Phlex's API to produce markup. Do not override this or you will lose your layout.
  # This implementation locates the configured layout, renders it, and renders {#page_template}
  # inside.
  def view_template
    with_layout do
      page_template
    end
  end


  # @return [String] name of this page for use in debugging or for whatever reason you may want to dynamically refer to the page's name.  The default value is the class name.
  def self.page_name = self.name

  # Convienience method for {.page_name}.
  def page_name = self.class.page_name

private

  # Locates the layout class and uses it to render itself, along
  # with the block given.
  #
  # @!visibility private
  def with_layout(&block)
    layout_class = Module.const_get(
      layout_class = RichString.new([
        self.layout,
        "layout",
      ].join("_")).camelize
    )
    Brut.container.instrumentation.add_prefixed_attributes("brut", layout_class: layout_class)
    render layout_class.new(page:self,&block)
  end



end

# Holds pages included with the Brut framework
module Brut::FrontEnd::Pages
  autoload(:MissingPage,"brut/front_end/pages/missing_page.rb")
end
