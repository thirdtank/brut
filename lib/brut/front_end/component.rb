require "json"
require "rexml"
require_relative "template"

module Brut::FrontEnd::Components
  autoload(:FormTag,"brut/front_end/components/form_tag")
  autoload(:Input,"brut/front_end/components/input")
  autoload(:Inputs,"brut/front_end/components/input")
  autoload(:I18nTranslations,"brut/front_end/components/i18n_translations")
  autoload(:Timestamp,"brut/front_end/components/timestamp")
  autoload(:PageIdentifier,"brut/front_end/components/page_identifier")
  autoload(:LocaleDetection,"brut/front_end/components/locale_detection")
end
# A Component is the top level class for managing the rendering of 
# content.  A component is essentially an ERB template and a class whose
# instance servces as it's binding.
#
# The component has a few more smarts and helpers.
class Brut::FrontEnd::Component
  using Brut::FrontEnd::Templates::HTMLSafeString::Refinement

  class TemplateLocator
    def initialize(paths:, extension:)
      @paths     = Array(paths).map { |path| Pathname(path) }
      @extension = extension
    end

    def locate(base_name)
      paths_to_try = @paths.map { |path|
        path / "#{base_name}.#{@extension}"
      }
      paths_found = paths_to_try.select { |path|
        path.exist?
      }
      if paths_found.empty?
        raise "Could not locate template for #{base_name}. Tried: #{paths_to_try.map(&:to_s).join(', ')}"
      end
      if paths_found.length > 1
        raise "Found more than one valid pat for #{base_name}.  You must rename your files to disambiguate them. These paths were all found: #{paths_found.map(&:to_s).join(', ')}"
      end
      return paths_found[0]
    end
  end

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

  attr_writer :yielded_block

  def render_yielded_block
    if @yielded_block
      @yielded_block.().html_safe!
    else
      raise Brut::FrontEnd::Errors::Bug, "No block was yielded to #{self.class.name}"
		end
	end

  # The core method of a component. This is expected to return
  # a string to be sent as a response to an HTTP request.
  #
  # This implementation uses the associated template for the component
  # and sends it through ERB using this component as
  # the binding.
  def render
    Brut.container.component_locator.locate(self.template_name).
      then { |erb_file| Brut::FrontEnd::Template.new(erb_file) }.
      then { |template| template.render_template(self).html_safe! }
  end

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

  def self.component_name = self.name
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
    # HTML template and render itself.
    def component(component_instance,&block)
      if component_instance.kind_of?(Class)
        if !component_instance.ancestors.include?(Brut::FrontEnd::Component)
          raise ArgumentError,"#{component_instance} is not a component and cannot be created"
        end
        component_instance = Thread.current.thread_variable_get(:request_context).
          then { |request_context| request_context.as_constructor_args(component_instance,request_params: nil)
        }.then { |constructor_args| component_instance.new(**constructor_args) }
      end
      if !block.nil?
        component_instance.yielded_block = block
      end
      request_context = Thread.current.thread_variable_get(:request_context).
        then { |request_context| request_context.as_method_args(component_instance,:render,request_params: nil, form: nil)
      }.then { |render_args| component_instance.render(**render_args).html_safe! }
    end

    # Inline an SVG into the page.
    def svg(svg)
      Brut.container.svg_locator.locate(svg).then { |svg_file|
        File.read(svg_file).html_safe!
      }
    end

    # Given a public path to an asset—the value you'd use in HTML—return
    # the same value, but with any content hashes that are part of the filename.
    def asset_path(path) = Brut.container.asset_path_resolver.resolve(path)

    # Render a form that should include CSRF protection.
    def form_tag(**attributes,&block)
      component(Brut::FrontEnd::Components::FormTag.new(**attributes,&block))
    end

    def timestamp(timestamp, **component_options)
      component(Brut::FrontEnd::Components::Timestamp.new(**(component_options.merge(timestamp:))))
    end

    def html_safe!(string)
      string.html_safe!
    end

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
