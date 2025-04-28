require "phlex"

# Components holds Brut-provided components that are of general use to any web app
module Brut::FrontEnd::Components
  autoload(:FormTag,"brut/front_end/components/form_tag")
  autoload(:Input,"brut/front_end/components/input")
  autoload(:Inputs,"brut/front_end/components/input")
  autoload(:I18nTranslations,"brut/front_end/components/i18n_translations")
  autoload(:Time,"brut/front_end/components/time")
  autoload(:PageIdentifier,"brut/front_end/components/page_identifier")
  autoload(:LocaleDetection,"brut/front_end/components/locale_detection")
  autoload(:ConstraintViolations,"brut/front_end/components/constraint_violations")
  autoload(:Traceparent,"brut/front_end/components/traceparent")
end

# A Component is the top level class for managing the rendering of 
# content.  A component is essentially an ERB template and a class whose
# instance servces as it's binding. It is very similar to a View Component, though
# not quite as fancy.
#
# When subclassing this to create a component, your initializer's signature will determine what data
# is required for your component to work.  It can be anything, just keep in mind that any page or component
# that uses your component must be able to provide those values.
#
# If your component does not override {#render} (which, generally, it won't), an ERB file is expected to exist alongside it in the
# app.  For example, if you have a component named `Auth::LoginButtonComponent`, it would expected to be in
# `app/src/front_end/components/auth/login_button_component.rb`.  Thus, Brut will also expect
# `app/src/front_end/components/auth/login_button_component.html.erb` to exist as well. That ERB file is used with an instance of your
# component's class to render the component's HTML.
#
# @see Brut::FrontEnd::Component::Helpers
class Brut::FrontEnd::Component < Phlex::HTML

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

  def self.component_name = self.name
  def component_name = self.class.component_name

  def page_name
    @page_name ||= begin
                     page = self.class.name.split(/::/).reduce(Module) { |accumulator,class_path_part|
                       if accumulator.ancestors.include?(Brut::FrontEnd::Page)
                         accumulator
                       else
                         accumulator.const_get(class_path_part)
                       end
                     }
                     if page.ancestors.include?(Brut::FrontEnd::Page)
                       page.name
                     elsif page.respond_to?(:page_name)
                       page.page_name
                     else
                       raise "#{self.class} is not nested inside a page, so #page_name should not have been called"
                     end
                   end
  end

end
