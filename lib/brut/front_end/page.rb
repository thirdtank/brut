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
class Brut::FrontEnd::Page < Phlex::HTML#Brut::FrontEnd::Component
  include Brut::FrontEnd::HandlingResults
  include Brut::Framework::Errors
  include Brut::I18n::ForHTML

  register_element :brut_confirm_submit
  register_element :brut_confirmation_dialog
  register_element :brut_cv
  register_element :brut_ajax_submit
  register_element :brut_autosubmit
  register_element :brut_confirm_submit
  register_element :brut_confirmation_dialog
  register_element :brut_cv
  register_element :brut_cv_messages
  register_element :brut_copy_to_clipboard
  register_element :brut_form
  register_element :brut_i18n_translation
  register_element :brut_locale_detection
  register_element :brut_message
  register_element :brut_tabs
  register_element :brut_tracing

  def inline_svg(svg)
    Brut.container.svg_locator.locate(svg).then { |svg_file|
      File.read(svg_file)
    }.then { |svg_content|
      raw(safe(svg_content))
    }
  end

  def time_tag(timestamp:nil,**component_options, &contents)
    args = component_options.merge(timestamp:)
    render Brut::FrontEnd::Components::Time.new(**args,&contents)
  end

  def form_tag(**args, &block)
    render Brut::FrontEnd::Components::FormTag.new(**args,&block)
  end

  def global_component(component_klass)
    render Brut::FrontEnd::RequestContext.inject(component_klass)
  end



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


  def with_layout(&block)
    layout_class = Module.const_get(
      layout_class = RichString.new([
        self.layout,
        "layout"
      ].join("_")).camelize
    )
    render layout_class.new(page_name:,&block)
  end


  def handle!
    case before_render
    in URI => uri
      uri
    in Brut::FrontEnd::HttpStatus => http_status
      http_status
    else
      self.call
    end
  end

  def view_template
    with_layout do
      page_template
    end
  end


  # @return [String] name of this page for use in debugging or for whatever reason you may want to dynamically refer to the page's name.  The default value is the class name.
  def self.page_name = self.name

  # Convienience method for {.page_name}.
  def page_name = self.class.page_name

  # @!visibility private
  def component_name = raise Brut::Framework::Errors::Bug,"#{self.class} is not a component"

end

# Holds pages included with the Brut framework
module Brut::FrontEnd::Pages
  autoload(:MissingPage,"brut/front_end/pages/missing_page.rb")
end
