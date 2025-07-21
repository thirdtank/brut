require "phlex"

# Namespace for Brut-provided components that are of general use to any web app.
# Also extends [`Phlex:::Kit`](https://www.phlex.fun/components/kits.html), meaning
# you can include this module in your pages and components to be able to 
# create Brut's components without `.new` or without the full classname:
#
# @example
#   class AppPage < Brut::FrontEnd::Page
#     include Brut::FrontEnd::Components
#   end
#
#   class HomePage < AppPage
#     def page_template
#     h1 do
#       span { "It's }
#       TimeTag(timestamp: Time.now)
#     end
#   end
module Brut::FrontEnd::Components
  autoload(:FormTag,"brut/front_end/components/form_tag")
  autoload(:Input,"brut/front_end/components/input")
  autoload(:Inputs,"brut/front_end/components/input")
  autoload(:I18nTranslations,"brut/front_end/components/i18n_translations")
  autoload(:TimeTag,"brut/front_end/components/time_tag")
  autoload(:PageIdentifier,"brut/front_end/components/page_identifier")
  autoload(:LocaleDetection,"brut/front_end/components/locale_detection")
  autoload(:ConstraintViolations,"brut/front_end/components/constraint_violations")
  autoload(:Traceparent,"brut/front_end/components/traceparent")

  extend Phlex::Kit
end

# A Component is the top level class for managing the rendering of 
# content.  It is a Phlex component with additional features.
# Components are the primary mechanism for managing view complexity and managing
# markup re-use in Brut.
#
# To create a component, subclass this class (or, more likely, your app's `AppComponent`) and
# provide an initializer that accepts keyword arguments.  The names of these arguments will be used to locate the
# values that Brut will pass in when creating your component object.
#
# Consult Brut's documentation on keyword injection to know what values you may use and how values are located.
#
# Becuase this is a Phlex component, you must implement `view_template` and make calls to Phlex's API to create
# the markup for your component.
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

  # Module for the various "free methods" available to all components.
  # Generally, we don't want to build up mega-classes with lots of modules, but
  # this provides a nice, singular namespace to document the helpers as apart
  # from the various methods of the component.
  module Helpers
    # Render an inline an SVG that is part of your app. **Note** this does not
    # return the SVG's contents, but it renders it into the current Phlex
    # context.
    #
    # @param [String] svg path to the SVG file, relative to where SVGs are
    #        stored, which is `app/src/front_end/svgs` or where `Brut.container.svg_locator` is
    #        looking
    #
    # @see Brut::FrontEnd::InlineSvgLocator
    def inline_svg(svg)
      Brut.container.svg_locator.locate(svg).then { |svg_file|
        File.read(svg_file)
      }.then { |svg_content|
        raw(safe(svg_content))
      }
    end

    # Render (in Phlex parlance) a component that you would like Brut to
    # instantiate.  This is useful when you want to use a component that
    # only requires values from the {Brut::FrontEnd::RequestContext}. By
    # using this method, *this* component does not have to receive
    # data from the {Brut::FrontEnd::RequestContext} that only serves to pass
    # to the component you use here.
    #
    # For example, you may have a component that renders the flash message.  To avoid requiring *this* component/page to be passed the flash, a global component can be injected with it from Brut.
    #
    # This component *will* be rendered into the Phlex context. Do not call
    # `render` on the result, nor rely on the return value.
    #
    # @param [Class] component_klass the component class to use in the view.
    #        This class's
    #        initializer must only require information available from the 
    #        {Brut::FrontEnd::RequestContext}.
    def global_component(component_klass)
      render Brut::FrontEnd::RequestContext.inject(component_klass)
    end

    # Add an HTML entity to the Phlex output.  This avoids having to call `raw(safe("%nsbp;"))` or
    # whatever.
    #
    # @param [Number|String] value the value of the entity **without** leading ampersand or trailing
    #        semicolon.
    # @return [void] Do not rely on the return value. This will mutate the current Phlex context.
    def entity(value)
      raw(safe("&#{value};"))
    end

  end
  include Helpers

  # The name of this component, used for debugging and other purposes. Do not
  # override this.
  def self.component_name = self.name
  # Convenience method to get the component name. This just calls the class
  # method {.component_name}.
  def component_name = self.class.component_name

  # True if this component is page private.
  # @!visibility private
  def page_private? = !!self.containing_page_class

  # Returns the {Brut::FrontEnd::Page.page_name} of the page containing this component, 
  # if it is {#page_private?}. Do not call if it's not.
  # @!visibility private
  def containing_page_name = self.containing_page_class.page_name

  # Override's Phlex' callback to add instrumentation to the `view_template` method.
  def around_template
    Brut.container.instrumentation.span(self.class.name + "#view_template") do |span|
      span.add_prefixed_attributes("brut", type: :component, class: self.class)
      super
    end
  end

private

  def containing_page_class
    page_class = self.class.name.split(/::/).reduce(Module) { |accumulator,class_path_part|
      if accumulator.ancestors.include?(Brut::FrontEnd::Page)
        accumulator
      else
        accumulator.const_get(class_path_part)
      end
    }
    if page_class.ancestors.include?(Brut::FrontEnd::Page)
      page_class
    else
      nil
    end
  end
end
