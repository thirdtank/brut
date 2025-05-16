require "phlex"

# Components holds Brut-provided components that are of general use to any web app
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

    # Convenience method for 
    # {Brut::FrontEnd::Components::TimeTag.new}.
    def time_tag(...)
      Brut::FrontEnd::Components::TimeTag.new(...)
    end

    # Return a component that you would like Brut to instantiate.
    # This will use keyword injection to create the component, which means that if the component
    # doesn't require any data from this component, you do not need to pass through those values.
    # For example, you may have a component that renders the flash message.  To avoid requiring your component to
    # be passed the flash, a global component can be injected with it from Brut.
    #
    # @return [Object] instance of `component_klass`, as created by Brut. This will
    #         not render the component.
    def global_component(component_klass)
      Brut::FrontEnd::RequestContext.inject(component_klass)
    end

    # Convenience method for 
    # {Brut::FrontEnd::Components::ConstraintViolations.new}.
    def constraint_violations(...)
      Brut::FrontEnd::Components::ConstraintViolations.new(...)
    end

    # Convenience method for 
    # {Brut::FrontEnd::Components::Inputs::TextField.for_form_input}.
    def input_tag(...)
      Brut::FrontEnd::Components::Inputs::TextField.for_form_input(...)
    end

    # Convenience method for 
    # {Brut::FrontEnd::Components::Inputs::Select.for_form_input}.
    def select_tag_with_options(...)
      Brut::FrontEnd::Components::Inputs::Select.for_form_input(...)
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
