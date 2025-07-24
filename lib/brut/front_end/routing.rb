require "uri"
require "phlex"

# Holds the registered routes for this app.
class Brut::FrontEnd::Routing

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
      elsif route.class == MissingPage || route.class == MissingHandler || route.class == MissingForm
        route.class.new(route.path_template,route.exception)
      elsif route.class == MissingPath
        route.class.new(route.method,route.path_template,route.exception)
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
    route = begin
              Route.new(method, path)
            rescue Brut::Framework::Errors::NoClassForPath => ex
              if Brut.container.project_env.development?
                MissingPath.new(method,path,ex)
              else
                raise ex
              end
            end
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
      if handler_class.ancestors.include?(Brut::FrontEnd::Form)
        raise ArgumentError,"There is no configured route for the form #{handler_class} and/or the handler class for this form doesn't exist"
      else
        raise ArgumentError,"There is no configured route for #{handler_class}"
      end
    end
    route
  end

  def path(handler_class, with_method: :any, **rest)
    route = self.route_for(handler_class, with_method:)
    route.path(**rest)
  end

  def url(handler_class, with_method: :any, **rest)
    route = self.route_for(handler_class, with_method:)
    route.url(**rest)
  end

  def inspect
    @routes.map { |route|
      "#{route.http_method}:#{route.path_template} - #{route.handler_class.name}"
    }.join("\n")
  end

private

  def route_for(handler_class, with_method: :any)
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
    route
  end


  def add_routing_method(route)
    handler_class = route.handler_class
    form_class = route.respond_to?(:form_class) ? route.form_class : nil
    [ handler_class, form_class ].compact.each do |klass|
      klass.class_eval do
        def self.routing(**args)
          Brut.container.routing.path(self,**args)
        end
        def self.full_routing(**args)
          Brut.container.routing.url(self,**args)
        end
      end
    end
  end

  class Route

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

    def path_params
      @path_template.split(/\//).map { |path_part|
        if path_part =~ /^:(.+)$/
          $1.to_sym
        else
          nil
        end
      }.compact
    end

    def path(**query_string_params)
      anchor = query_string_params.delete(:anchor) || query_string_params.delete("anchor")
      path = @path_template.split(/\//).map { |path_part|
        if path_part =~ /^:(.+)$/
          param_name = $1.to_sym
          if !query_string_params.key?(param_name)
            raise Brut::Framework::Errors::MissingParameter.new(
              param_name,
              params_received: query_string_params.keys,
              context: ":#{param_name} was used as a path parameter for #{@handler_class} (path '#{@path_template}')"
            )
          end
          query_string_params.delete(param_name)
        else
          path_part
        end
      }
      joined_path = path.join("/")
      if joined_path == ""
        joined_path = "/"
      end
      if anchor
        joined_path = joined_path + "#" + URI.encode_uri_component(anchor)
      end
      uri = URI(joined_path)
      query_string = URI.encode_www_form(query_string_params)
      if query_string.to_s.strip != ""
        uri.query = query_string
      end

      uri.extend(Phlex::SGML::SafeObject)
    end

    def url(**query_string_params)
      request_context = Brut::FrontEnd::RequestContext.current
      path = self.path(**query_string_params)
      host = if request_context
               request_context[:host]
             end
      host ||= Brut.container.fallback_host
      host.merge(path)
    rescue ArgumentError => ex
      request_context_note = if request_context
                               "the RequestContext did not contain request.host, which is unusual"
                             else
                               "the RequestContext was not available (likely due to calling `full_routing` outside an HTTP request)"
                             end
      raise Brut::Framework::Errors::MissingConfiguration(
        :fallback_host,
        "Attempting to get the full URL for route #{self.path_template}, #{request_context_note}, and Brut.container.fallback_host was not set.  You must set this value if you expect to generate complete URLs outside of an HTTP request")
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
        part_names.reduce(Module) { |mod,path_element|
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
      @handler_class = begin
                         handler_class = Class.new(Brut::FrontEnd::Handlers::MissingHandler)
                         compressed_class_name = ex.class_name_path.join
                         Module.const_set(:"BrutMissingHandlers#{compressed_class_name}",handler_class)
                         handler_class
                       end
      @exception     = ex
    end
  end

  class MissingPath < Route
    attr_reader :exception
    def initialize(method,path_template,ex)
      @http_method   = Brut::FrontEnd::HttpMethod.new(method)
      @path_template = path_template
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

