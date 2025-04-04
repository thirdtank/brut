require "json"
require "rexml"
require_relative "template"

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
class Brut::FrontEnd::Component
  using Brut::FrontEnd::Templates::HTMLSafeString::Refinement


  # @!visibility private
  class AssetPathResolver
    def initialize(metadata_file:)
      @metadata_file = metadata_file
      reload
    end

    def reload
      @asset_metadata = Brut::FrontEnd::AssetMetadata.new(asset_metadata_file: @metadata_file)
      @asset_metadata.load!
    end

    def resolve(path)
      @asset_metadata.resolve(path)
    end
  end

  # Allows helpers that create components to pass the block they were given to the component.
  # This can be read for the purposes of nested components passing a yielded block to an inner
  # component
  attr_accessor :yielded_block

  # Intended to be called by subclasses to render the yielded block wherever it makes sense in their markup.
  def render_yielded_block
    if @yielded_block
      @yielded_block.().html_safe!
    else
      raise Brut::Framework::Errors::Bug, "No block was yielded to #{self.class.name}"
		end
	end

  # The core method of a component. This is expected to return
  # a string to be sent as a response to an HTTP request. Generally, you should not call this method
  # as it is intended to be called from {Brut::FrontEnd::Component::Helpers#component}.
  #
  # This implementation uses the associated template for the component
  # and sends it through ERB using this component as
  # the binding.
  #
  # You may override this method to provide your own HTML for the component. In doing so, you can add
  # keyword args for data from the `RequestContext` you wish to receive. See {Brut::FrontEnd::RequestContext#as_method_args}.
  #
  # @return [Brut::FrontEnd::Templates::HTMLSafeString] string containing the component's HTML.
  def render
    Brut.container.instrumentation.span("#{self.class} render") do |span|
      span.add_prefixed_attributes("brut", type: :component, class: self.class.name)
      Brut.container.component_locator.locate(self.template_name).
        then { Brut::FrontEnd::Template.new(it) }.
        then { it.render_template(self).html_safe! }
    end
  end

  # For components that are private to a page, this returns the name of the page they are a part of.
  # This is used to allow a component to render a page's I18n strings.
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
                     else
                       raise "#{self.class} is not nested inside a page, so #page_name should not have been called"
                     end
                   end
  end

  # Used when an I18n string needs access to component-specific translations
  def self.component_name = self.name
  # (see .component_name)
  def component_name = self.class.component_name

  # Helper methods that subclasses can use.
  # This is a separate module to distinguish the public
  # interface of this class (`render`) from these helper methods
  # that are useful to subclasses and their templates.
  #
  # This is not intended to be extracted or used outside this class!
  module Helpers

    # Render a component. This is the primary way in which
    # view re-use happens.  The component instance will be able to locate its
    # HTML template and render itself.  {#render} is called with variables from the `RequestContext`
    # as described in {Brut::FrontEnd::RequestContext#as_method_args}
    #
    # @param [Brut::FrontEnd::Component|Class] component_instance instance of the component to render. If a `Class`
    #                                          is passed, it must extend {Brut::FrontEnd::Component}. It will created
    #                                          based on the logic described in {Brut::FrontEnd::RequestContext#as_constructor_args}.
    #                                          You would do this if your component needs to be injected with information 
    #                                          not available to the page or component that is using it.
    # @yield this block is passed to the `component_instance` via {#yielded_block=}.
    #
    # @return [Brut::FrontEnd::Templates::HTMLSafeString] of the rendered component.
    def component(component_instance,&block)
      component_name = component_instance.kind_of?(Class) ? component_instance.name : component_instance.class.name
      Brut.container.instrumentation.span("component #{component_name}") do |span|
        if component_instance.kind_of?(Class)
          if !component_instance.ancestors.include?(Brut::FrontEnd::Component)
            raise ArgumentError,"#{component_instance} is not a component and cannot be created"
          end
          component_instance = Thread.current.thread_variable_get(:request_context).
            then { |request_context| request_context.as_constructor_args(component_instance,request_params: nil)
            }.then { |constructor_args| component_instance.new(**constructor_args) }
          span.add_prefixed_attributes("brut", "global_component" => true)
        else
          span.add_prefixed_attributes("brut", "global_component" => false)
        end
        if !block.nil?
          component_instance.yielded_block = block
        end
        Thread.current.thread_variable_get(:request_context).then {
          it.as_method_args(component_instance,:render,request_params: nil, form: nil)
        }.then { |render_args|
          component_instance.render(**render_args).html_safe!
        }
      end
    end

    # Inline an SVG into the page.
    #
    # @param [String] svg name of an SVG file, relative to where SVGs are stored.
    def svg(svg)
      Brut.container.svg_locator.locate(svg).then { |svg_file|
        File.read(svg_file).html_safe!
      }
    end

    # Given a public path to an asset—the value you'd use in HTML—return
    # the same value, but with any content hashes that are part of the filename.
    def asset_path(path) = Brut.container.asset_path_resolver.resolve(path)

    # (see Brut::FrontEnd::Components::FormTag)
    def form_tag(route_params: {}, **html_attributes,&contents)
      component(Brut::FrontEnd::Components::FormTag.new(route_params:, **html_attributes,&contents))
    end

    # Creates a {Brut::FrontEnd::Components::Time}.
    #
    # @param timestamp [Time] the timestamp to format/render. Mutually exclusive with `date`.
    # @param date [Date] the date to format/render. Mutually exclusive with `timestamp`.
    # @param component_options [Hash] keyword arguments to pass to {Brut::FrontEnd::Components::Time#initialize}
    # @yield See {Brut::FrontEnd::Components::Time#initialize}
    def time_tag(timestamp:nil,date:nil, **component_options, &contents)
      args = component_options.merge(timestamp:,date:)
      component(Brut::FrontEnd::Components::Time.new(**args,&contents))
    end

    # Render the {Brut::FrontEnd::Components::ConstraintViolations} component for the given form's input.
    def constraint_violations(form:, input_name:, index: nil, message_html_attributes: {}, **html_attributes)
      component(
        Brut::FrontEnd::Components::ConstraintViolations.new(
          form:,
          input_name:,
          index:,
          message_html_attributes:,
          **html_attributes
        )
      )
    end

    # Create an HTML input tag for the given input of a form.  This is a convieniece method
    # that calls {Brut::FrontEnd::Components::Inputs::TextField.for_form_input}.
    def input_tag(form:, input_name:, index: nil, **html_attributes)
      component(Brut::FrontEnd::Components::Inputs::TextField.for_form_input(form:,input_name:,index:,html_attributes:))
    end

    # Indicates a given string is safe to render directly as HTML. No escaping will happen.
    #
    # @param [String] string a string that should be marked as HTML safe
    def html_safe!(string)
      string.html_safe!
    end

    # @!visibility private
    VOID_ELEMENTS = [
      :area,
      :base,
      :br,
      :col,
      :embed,
      :hr,
      :img,
      :input,
      :link,
      :meta,
      :source,
      :track,
      :wbr,
    ]

    # Generate an HTML element safely in code.  This is useful if you don't want to create
    # a separate ERB file, but still want to create a component.
    #
    # @param [String|Symbol] tag_name the name of the HTML tag to create.
    # @param [Hash] html_attributes all the HTML attributes you wish to include in the element that is generated.  Values that
    #                                 are `true` will be included without a value, and values that are `false` will be omitted.
    # @yield Called to get any contents that should be put into this tag.  Void elements as defined by W3C may not have a block.
    #
    # @example Void element
    #
    #     html_tag(:img, src: "trellick.png") # => <img src="trellic.png">
    #
    # @example Nested elements
    #
    #     html_tag(:nav, class: "flex items-center") do
    #       html_tag(:a, href="/") { "Home" } + 
    #       html_tag(:a, href="/about") { "About" } + 
    #       html_tag(:a, href="/contact") { "Contact" }
    #     end
    def html_tag(tag_name, **html_attributes, &block)
      tag_name = tag_name.to_s.downcase.to_sym
      attributes_string = html_attributes.map { |key,value|
        [
          key.to_s.gsub(/[\s\"\'>\/=]/,"-"),
          value
        ]
      }.select { |key,value|
        !value.nil?
      }.map { |key,value|
        if value == true
          key
        elsif value == false
          ""
        else
          REXML::Attribute.new(key,value).to_string
        end
      }.join(" ")
      contents = (block.nil? ? nil : block.()).to_s
      if VOID_ELEMENTS.include?(tag_name)
        if !contents.empty?
          raise ArgumentError,"#{tag_name} may not have child nodes"
        end
        html_safe!(%{<#{tag_name} #{attributes_string}>})
      else
        html_safe!(%{<#{tag_name} #{attributes_string}>#{contents}</#{tag_name}>})
      end
    end
  end
  include Helpers
  include Brut::I18n::ForHTML

private

  def binding_scope = binding

  # Determines the canonical name/location of the template used for this
  # component.  It does this base do the class name. CameCase is converted
  # to snake_case. 
  def template_name = RichString.new(self.class.name).underscorized.to_s.gsub(/^components\//,"")
end
