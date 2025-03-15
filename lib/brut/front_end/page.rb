# A page backs a web page.  A page renders everything in the browser window.  Technically, it is exactly like a component except that
# it can have a layout.
#
# When subclassing this to create a page, your initializer's signature will determine what data
# is required for your page to work.  It can be anything, just keep in mind that any component your page uses may
# require additional data.
#
# If your page does not override {#render} (which, generally, it won't), an ERB file is expected to exist alongside it in the
# app.  For example, if you have a page named `Auth::LoginPage`, it would expected to be in
# `app/src/front_end/pages/auth/login_page.rb`.  Thus, Brut will also expect
# `app/src/front_end/pages/auth/login_page.html.erb` to exist as well. That ERB file is used with an instance of your
# pages's class to render the page's HTML.
#
# @see Brut::FrontEnd::Component
class Brut::FrontEnd::Page < Brut::FrontEnd::Component
  include Brut::FrontEnd::HandlingResults
  using Brut::FrontEnd::Templates::HTMLSafeString::Refinement

  # Returns the name of the layout for this page.  This string is used to find an ERB file in `app/src/front_end/layouts`. Every page
  # must have a layout. If you wish to render a page with no layout, create an empty layout in your app and use that.
  #
  # Note that the layout can be dynamic. It is requested when {#render} is called, so you can override this
  # method and use any ivar set in your constructor to change what layout is used.
  #
  # @return [String] The name of the layout. May not be `nil`.
  def layout = "default"

  # Called after the page is created, but before {#render} is called.  This allows you to do any pre-flight checks and potentially
  # redirect the user or produce an error.
  #
  # @return [URI|Brut::FrontEnd::HttpStatus|Object] If you return a `URI` (mostly likely by returning the result of calling {Brut::FrontEnd::HandlingResults#redirect_to}), the user is redirected and {#render} is never called. If you return a {Brut::FrontEnd::HttpStatus} (mostly likely by returning the result of calling {Brut::FrontEnd::HandlingResults#http_status}), {#render} is skipped and that status is returned with no content.  If anything else is returned, {#render} is called as normal.
  def before_render = nil

  # @!visibility private
  def handle!
    case before_render
    in URI => uri
      Brut.container.instrumentation.add_event("before_render got a URI", uri: uri)
      uri
    in Brut::FrontEnd::HttpStatus => http_status
      Brut.container.instrumentation.add_event("before_render got status", http_status: http_status)
      http_status
    else
      render
    end
  end

  # The core method of a page, which overrides {Brut::FrontEnd::Component#render}. This is expected to return
  # a string to be sent as a response to an HTTP request. Generally, you should not call this method as it is
  # called by Brut when your page is requested.
  #
  # Also, generally don't override this unles you need to do something unusual.  Overriding this will completely bypass the layout
  # system and skip all ERB processing. Unlike {Brut::FrontEnd::Component#render}, overriding this method does not provide access to injected data from the request context.
  #
  # @return [Brut::FrontEnd::Templates::HTMLSafeString] string containing the page's full HTML.
  def render
    layout_template = Brut.container.layout_locator.locate(self.layout).
      then { |layout_erb_file| Brut::FrontEnd::Template.new(layout_erb_file) }

    template = Brut.container.page_locator.locate(self.template_name).
      then { |erb_file| Brut::FrontEnd::Template.new(erb_file) }

    Brut.container.instrumentation.add_event("templates found", layout: layout_template.template_file_path, page: template.template_file_path)

    page = template.render_template(self).html_safe!
    layout_template.render_template(self) do
      page
    end
  end

  # @return [String] name of this page for use in debugging or for whatever reason you may want to dynamically refer to the page's name.  The default value is the class name.
  def self.page_name = self.name

  # Convienience method for {.page_name}.
  def page_name = self.class.page_name

  # @!visibility private
  def component_name = raise Brut::Framework::Errors::Bug,"#{self.class} is not a component"

private

  def template_name = RichString.new(self.class.name).underscorized.to_s.gsub(/^pages\//,"")

end

# Holds pages included with the Brut framework
module Brut::FrontEnd::Pages
  autoload(:MissingPage,"brut/front_end/pages/missing_page.rb")
end
