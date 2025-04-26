module Brut::SinatraHelpers

  def self.included(sinatra_app)
    sinatra_app.extend(ClassMethods)

    sinatra_app.set :logging, false
    sinatra_app.set :public_folder, Brut.container.public_root_dir
    sinatra_app.path("/__brut/csp-reporting",method: :post)
    sinatra_app.path("/__brut/locale_detection",method: :post)
    sinatra_app.path("/__brut/instrumentation",method: :get)
    sinatra_app.set :host_authorization, permitted_hosts: Brut.container.permitted_hosts
  end

  # @private
  def render_html(component_or_page_instance)
    result = component_or_page_instance.render
    case result
    in Brut::FrontEnd::HttpStatus => http_status
      http_status.to_i
    else
      result
    end
  end


  module ClassMethods

    # Regsiters a page in your app. A page is what it sounds like - a web page that's rendered from a URL.  It will be provided
    # via an HTTP get to the path provided.
    #
    # The page is rendered dynamically by using an instance of a page class as binding to HTML via ERB.  The name of the class and the name of the
    # ERB file are based on the path, according to the conventions described below.
    #
    # A few examples:
    #
    # * `page("/widgets")` will use `WidgetsPage`, and expect the HTML in `app/src/pages/widgets_page.html.erb`
    # * `page("/widgets/:id")` will use `WidgetsByIdPage`, and expect the HTML in `app/src/pages/widgets_by_id_page.html.erb`
    # * `page("/admin/widgets/:internal_id") will use `Admin::WidgetsByInternalIdPage`, and expect HTML in
    # `app/src/pages/admin/widgets_by_internal_id_page.html.erb`
    #
    # The general conventions are:
    #
    # * Each part of the path that is not a placeholder will be camelized
    # * Any part of the path that *is* a placholder has its leading colon removed, then is camelized, but appended to
    #   the previous part with `By`, thus `WidgetsById` is created from `Widgets`, `By`, and `Id`.
    # * The final part of the path is further appended with `Page`.
    # * These parts now make up a path to a class, so the entire thing is joined by `::` to form the fully-qualified class name.
    #
    # When a  GET is issued to the path, the page is instantiated.  The page's constructor may accept keyword arguments (however it must not accept
    # any other type of argument).
    #
    # Each keyword argument found will be provided when the class is created, as follows:
    #
    # * Any placeholders, so when a path `/widgets/1234` is requested, `WidgetsPage.new(id: "1234")` will be used to create the page object.
    # * Anything in the request context, such as the current user
    # * Any query string parameters 
    # * Anything passed as keyword args to this method, with the following adjustment:
    #   - Any key ending in `_class` whose value is a Class will be instantiated and
    #     passed in as the key withoutr `_class`, e.g. form_class: SomeForm will
    #     pass `form: SomeForm.new` to the constructor
    # * The flash
    #
    # Once this page object exists, `render` will be called to produce HTML to send back to the browser.
    def page(path)
      Brut.container.routing.register_page(path)

      get path do
        brut_route = Brut.container.routing.for(path: path,method: :get)
        page_class = brut_route.handler_class
        path_template = brut_route.path_template

        root_span = env["brut.otel.root_span"]
        if root_span
          root_span.name = "GET #{path_template}"
          root_span.add_attributes("http.route" => path_template)
        end

        Brut.container.instrumentation.span(page_class.name) do |span|
          span.add_prefixed_attributes("brut", type: :page, class: page_class)
          request_context = Thread.current.thread_variable_get(:request_context)
          constructor_args = request_context.as_constructor_args(
            page_class,
            request_params: params,
            route: brut_route,
          )
          span.add_prefixed_attributes("brut.initializer.args", constructor_args.map { |k,v| [k.to_s,v.class.name] }.to_h)
          page_instance = page_class.new(**constructor_args)

          result = page_instance.handle!

          span.add_prefixed_attributes("brut", result_class: result.class)
          case result
          in URI => uri
            redirect to(uri.to_s)
          in Brut::FrontEnd::HttpStatus => http_status
            http_status.to_i
          else
            result
          end
        end
      end
    end

    # Declares a form that will be submitted to the app. To handle the submission you must providate
    # a handler and an optional form.  The form defines all the fields in your form, including constraints.
    # These can be used to generate HTML for the form.  When the form is submitted to your app, the form
    # is instantiated and filled in with all the values it is requesting.  That form is then passed off to the
    # configured handler.  The handle! method performs whatever processing is needed.
    #
    # If you have no form elements and are just responding to a POST action from a browser, use `action`.
    #
    # The name of the classes are based on a convention similar to `page`:
    #
    # * Each part of the path that is not a placeholder will be camelized
    # * Any part of the path that *is* a placholder has its leading colon removed, then is camelized, but appended to
    #   the previous part with `With`, thus `WidgetsWithId` is created from `Widgets`, `With`, and `Id`.
    # * The final part of the path is further appended with `Form` or `Handler`.
    # * These parts now make up a path to a class, so the entire thing is joined by `::` to form the fully-qualified class name.
    #
    # Examples:
    #
    # * `form("/widgets")` will use `WidgetsForm` and `WidgetsHandler`
    # * `form("/widgets/:id")` will use `WidgetsWithIdForm` and `WidgetsWithIdHandler`
    # * `form("/admin/widgets/:internal_id") will use `Admin::WidgetsWithInternalIdForm` and `Admin::WidgetsWithInternalIdHandler`
    #
    def form(path)
      route = Brut.container.routing.register_form(path)
      self.define_handled_route(route, type: :form)
    end

    # Declare a form action that has no associated form elements.  This is used when you need to use a button to submit to the
    # back-end, and the route contains all the context you need. For example a post to `/approved_widgets/:id` communicates that the 
    # Widget with ID `:id` can be approved.
    #
    # This is preferred over `path` because a) it's more explicit that this is handling a POST from some HTML and b) this will check
    # to make sure there is no form defined.
    def action(path)
      route = Brut.container.routing.register_handler_only(path)
      self.define_handled_route(route, type: :action)
    end

    # When you need to respond to a given path/method, but it's not a page nor a form.  For example, webhooks often
    # require responding to GET even though they aren't rendering pages nor considered to be idempotent.
    #
    # This will locate a handler class based on the same naming convention as for forms.
    def path(path, method:)
      route = Brut.container.routing.register_path(path, method: Brut::FrontEnd::HttpMethod.new(method))
      self.define_handled_route(route,type: :generic)
    end

  private

    def define_handled_route(original_brut_route,type:)

      method = original_brut_route.http_method.to_s.upcase
      path   = original_brut_route.path_template

      route method, path do
        # This must be re-looked up per-request do allow reloading to work
        brut_route = Brut.container.routing.for(path:,method:)

        path_template = brut_route.path_template

        root_span = env["brut.otel.root_span"]
        if root_span
          root_span.name = "#{method} #{path_template}"
          root_span.add_attributes("http.route" => path_template)
        end

        handler_class = brut_route.handler_class

        Brut.container.instrumentation.span(handler_class.name) do |span|

          form_class = brut_route.respond_to?(:form_class) ? brut_route.form_class : nil

          span.add_prefixed_attributes("brut",
            type: form_class ? :form : :action,
            class: handler_class,
            form_class: form_class,
          )

          request_context = Thread.current.thread_variable_get(:request_context)
          handler = handler_class.new
          form = if form_class.nil?
                   nil
                 else
                   form_class.new(params: params)
                 end

          process_args = request_context.as_method_args(handler,:handle,request_params: params,form: form,route:brut_route)

          result = handler.handle!(**process_args)

          case result
          in URI => uri
            redirect to(uri.to_s)
          in Brut::FrontEnd::Component => component_instance
            component_instance.call.to_s
          in [ Brut::FrontEnd::Component => component_instance, Brut::FrontEnd::HttpStatus => http_status ]
            [
              http_status.to_i,
              component_instance.call.to_s,
            ]
          in Brut::FrontEnd::HttpStatus => http_status
            http_status.to_i
          in Brut::FrontEnd::Download => download
            [ 200, download.headers, download.data ]
          in Brut::FrontEnd::GenericResponse => response
            response.to_ary
          else
            raise NoMatchingPatternError, "Result from #{handler.class}'s handle! method was a #{result.class}, which cannot be used to understand the response to generate"
          end
        end
      end
    end

  end
end
