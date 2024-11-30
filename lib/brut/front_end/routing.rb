require "uri"

# Holds the registered routes for this app.
class Brut::FrontEnd::Routing

  include SemanticLogger::Loggable

  def initialize
    @routes = Set.new
  end

  def for(path:,method:)
    http_method = Brut::FrontEnd::HttpMethod.new(method)
    @routes.detect { |route|
      route.path_template == path &&
        route.http_method == http_method
    }
  end

  def reload
    new_routes = @routes.map { |route|
      if route.class == Route
        route.class.new(route.http_method,route.path_template)
      elsif route.class == MissingPage || route.class == MissingHandler
        route.class.new(route.path_template,route.exception)
      else
        route.class.new(route.path_template)
      end
    }
    @routes = Set.new(new_routes)
    @routes.each do |route|
      handler_class = route.handler_class
      if handler_class.name !~ /^Brut::[A-Z]/
        add_routing_method(route)
      end
    end
  end

  def register_page(path)
    route = begin
              PageRoute.new(path)
            rescue Brut::Framework::Errors::NoClassForPath => ex
              if Brut.container.project_env.development?
                MissingPage.new(path,ex)
              else
                raise ex
              end
            end
    @routes << route
    add_routing_method(route)
    route
  end

  def register_form(path)
    route = begin
              FormRoute.new(path)
            rescue Brut::Framework::Errors::NoClassForPath => ex
              if Brut.container.project_env.development?
                MissingForm.new(path,ex)
              else
                raise ex
              end
            end
    @routes << route
    add_routing_method(route)
    route
  end

  def register_handler_only(path)
    route = begin
              FormHandlerRoute.new(path)
            rescue Brut::Framework::Errors::NoClassForPath => ex
              if Brut.container.project_env.development?
                MissingHandler.new(path,ex)
              else
                raise ex
              end
            end
    @routes << route
    add_routing_method(route)
    route
  end

  def register_path(path, method:)
    route = Route.new(method, path)
    @routes << route
    add_routing_method(route)
    route
  end

  def route(handler_class)
    route = @routes.detect { |route|
      handler_class_match = route.handler_class.name == handler_class.name
      form_class_match = if route.respond_to?(:form_class)
                           route.form_class.name == handler_class.name
                         else
                           false
                         end
      handler_class_match || form_class_match
    }
    if !route
      raise ArgumentError,"There is no configured route for #{handler_class}"
    end
    route
  end

  def uri(handler_class, with_method: :any, **rest)
    route = self.route(handler_class)
    route_allowed_for_method = if with_method == :any
                                 true
                               elsif Brut::FrontEnd::HttpMethod.new(with_method) == route.http_method
                                 true
                               else
                                 false
                               end
    if !route_allowed_for_method
      raise ArgumentError,"The route for '#{handler_class}' (#{route.path}) is not supported by HTTP method '#{with_method}'"
    end
    route.path(**rest)
  end

  def inspect
    @routes.map { |route|
      "#{route.http_method}:#{route.path_template} - #{route.handler_class.name}"
    }.join("\n")
  end

  def add_routing_method(route)
    handler_class = route.handler_class
    if handler_class.respond_to?(:routing) && handler_class.method(:routing).owner != Brut::FrontEnd::Form
      raise ArgumentError,"#{handler_class} (that handles path #{route.path_template}) got it's ::routing method from #{handler_class.method(:routing).owner}, meaning it has overridden the value fro Brut::FrontEnd::Form"
    end
    form_class = route.respond_to?(:form_class) ? route.form_class : nil
    [ handler_class, form_class ].compact.each do |klass|
      klass.class_eval do
        def self.routing(**args)
          Brut.container.routing.uri(self,**args)
        end
      end
    end
  end

  class Route

    include SemanticLogger::Loggable

    attr_reader :handler_class, :path_template, :http_method

    def initialize(method,path_template)
      http_method = Brut::FrontEnd::HttpMethod.new(method)
      if ![:get, :post].include?(http_method.to_sym)
        raise ArgumentError,"Only GET and POST are supported. '#{method}' is not"
      end
      if path_template !~ /^\//
        raise ArgumentError,"Routes must start with a slash: '#{path_template}'"
      end
      @http_method   = http_method
      @path_template = path_template
      @handler_class = self.locate_handler_class(self.suffix,self.preposition)
    end

    def path(**query_string_params)
      path = @path_template.split(/\//).map { |path_part|
        if path_part =~ /^:(.+)$/
          param_name = $1.to_sym
          if !query_string_params.key?(param_name)
            query_string_params_for_message = if query_string_params.keys.any?
                                                query_string_params.keys.map(&:to_s).join(", ")
                                              else
                                                "no params"
                                              end
            raise ArgumentError,"path for #{@handler_class} requires '#{param_name}' as a path parameter, but it was not specified to #path. Got #{query_string_params_for_message}"
          end
          query_string_params.delete(param_name)
        else
          path_part
        end
      }
      uri = URI(path.join("/"))
      uri.query = URI.encode_www_form(query_string_params)
      uri
    end

    def ==(other)
      self.method == other.method && self.path == other.path
    end

  private
    def locate_handler_class(suffix,preposition, on_missing: :raise)
      if @path_template == "/"
        return Module.const_get("HomePage") # XXX Needs error handling
      end
      path_parts = @path_template.split(/\//)[1..-1]

      part_names = path_parts.reduce([]) { |array,path_part|
        if path_part =~ /^:(.+)$/
          if array.empty?
            raise ArgumentError,"Your path may not start with a placeholder: '#{@path_template}'"
          end
          placeholder_camelized = RichString.new($1).camelize
          array[-1] << preposition
          array[-1] << placeholder_camelized.to_s
        elsif array.empty? && path_part == "__brut"
          array << "Brut"
          array << "FrontEnd"
          array << "Handlers"
        else
          array << RichString.new(path_part).camelize.to_s
        end
        array
      }
      part_names[-1] += suffix
      begin
        part_names.inject(Module) { |mod,path_element|
          mod.const_get(path_element,mod == Module)
        }
      rescue NameError => ex
        if on_missing == :raise
          raise Brut::Framework::Errors::NoClassForPath.new(
            class_name_path: part_names,
            path_template: @path_template,
            name_error: ex,
          )
        else
          nil
        end
      end
    end

    def suffix = "Handler"
    def preposition = "With"

  end

  class MissingPage < Route
    attr_reader :exception
    def initialize(path_template,ex)
      @http_method   = Brut::FrontEnd::HttpMethod.new(:get)
      @path_template = path_template
      @handler_class = begin
                         page_class = Class.new(Brut::FrontEnd::Pages::MissingPage)
                         compressed_class_name = ex.class_name_path.join
                         Module.const_set(:"BrutMissingPages#{compressed_class_name}",page_class)
                         page_class
                       end
      @exception     = ex
    end
  end

  class MissingHandler < Route
    attr_reader :exception
    def initialize(path_template,ex)
      @http_method   = Brut::FrontEnd::HttpMethod.new(:post)
      @path_template = path_template
      @handler_class = Brut::FrontEnd::Handlers::MissingHandler
      @handler_class = begin
                         handler_class = Class.new(Brut::FrontEnd::Handlers::MissingHandler)
                         compressed_class_name = ex.class_name_path.join
                         Module.const_set(:"BrutMissingHandlers#{compressed_class_name}",handler_class)
                         handler_class
                       end
      @exception     = ex
    end
  end

  class MissingForm < MissingHandler
    attr_reader :form_class
    def initialize(path_template,ex)
      super
      @form_class    = Brut::FrontEnd::Handlers::MissingHandler::Form
      @form_class = begin
                      form_class = Class.new(Brut::FrontEnd::Handlers::MissingHandler::Form)
                      compressed_class_name = ex.class_name_path.join
                      Module.const_set(:"BrutMissingForms#{compressed_class_name}",form_class)
                      form_class
                    end
    end
  end

  class PageRoute < Route
    def initialize(path_template)
      super(Brut::FrontEnd::HttpMethod.new(:get),path_template)
    end
    def suffix = "Page"
    def preposition = "By"
  end

  class FormRoute < Route
    attr_reader :form_class
    def initialize(path_template)
      super(Brut::FrontEnd::HttpMethod.new(:post),path_template)
      @form_class = self.locate_handler_class("Form","With")
    end
  end

  class FormHandlerRoute < Route
    def initialize(path_template)
      super(Brut::FrontEnd::HttpMethod.new(:post),path_template)
      unnecessary_class = self.locate_handler_class("Form","With", on_missing: nil)
      if !unnecessary_class.nil?
        raise ArgumentError,"#{path_template} should only have #{handler_class} defined, however #{unnecessary_class} was found. If #{path_template} should be a form submission, use `form \"#{path_template}\"` instead of `action \"#{path_template}\"`. Otherwise, delete #{unnecessary_class}"
      end
    end
  end

end

