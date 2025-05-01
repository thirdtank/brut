# Represents a `<form>` HTML element that includes a CSRF token as needed. You likely want to use this class via the {Brut::FrontEnd::Component::Helpers#form_tag} method.
class Brut::FrontEnd::Components::FormTag < Brut::FrontEnd::Component
  # Creates the form surrounding the contents of the block yielded to it. If the form's action is a POST, it will include a CSRF token.
  # If the form's action is GET, it will not.
  #
  # @example Route without parameters
  #   <%= form_tag(for: NewWidgetForm, class: "new-form") do %>
  #     <input type="text" name="name">
  #     <button>Create</button>
  #   <% end %>
  #
  # @example Route with parameters
  #   <%= form_tag(for: SaveWidgetWithIdForm, route_params: { id: widget.external_id }, class: "new-form") do %>
  #     <input type="text" name="name">
  #     <button>Save</button>
  #   <% end %>
  #
  # @param route_params [Hash] if the form requires route parameters, their values must be passed here so that the HTML `action`
  # attribute can be constructed properly.
  # @param html_attributes [Hash] any additional attributes for the `<form>` tag
  # @option html_attributes [Class|Brut::FrontEnd::Form] :for the form object or class representing this HTML form *or* the class of a handler the form should submit to. If you pass this, you may not pass the HTML attributes `:action` or `:method`. Both will be derived from this object.
  # @option html_attributes [String] «any-other-key» attributes to set on the `<form>` tag
  # @yield No parameters given. This is expected to return additional markup to appear inside the `<form>` element.
  def initialize(route_params: {}, **html_attributes)
    form_class = html_attributes.delete(:for) # Cannot be a keyword arg, since for is a reserved word
    if !form_class.nil?
      if form_class.kind_of?(Brut::FrontEnd::Form)
        form_class = form_class.class
      end
      if html_attributes[:action]
        raise ArgumentError, "You cannot specify both for: (#{form_class}) and and action: (#{html_attributes[:action]}) to a form_tag"
      end
      if html_attributes[:method]
        raise ArgumentError, "You cannot specify both for: (#{form_class}) and and method: (#{html_attributes[:method]}) to a form_tag"
      end
      begin
        route = Brut.container.routing.route(form_class)
        html_attributes[:method] = route.http_method
        html_attributes[:action] = route.path(**route_params)
      rescue Brut::Framework::Errors::MissingParameter
        raise ArgumentError, "You specified #{form_class} (or an instance of it), but it requires more url parameters than were found in route_params: (or route_params: was omitted). Please add all required parameters to route_params: or use `action: #{form_class}.routing(..params..), method: [:get|:post]` instead"
      end
    end

    @csrf_token_omit_reasoning = nil

    http_method = Brut::FrontEnd::HttpMethod.new(html_attributes[:method])

    @include_csrf_token = http_method.post?
    @csrf_token_omit_reasoning = http_method.get? ? "because this form's action is a GET" : nil
    @attributes = html_attributes.merge(method: http_method)
  end

  def view_template
    form(**@attributes) do
      if @include_csrf_token
        render Brut::FrontEnd::RequestContext.inject(Brut::FrontEnd::Components::Inputs::CsrfToken)
      elsif Brut.container.project_env.development?
        comment do
          "CSRF Token omitted #{@csrf_token_omit_reasoning} (this message only appears in development)"
        end
      end
      if block_given?
        yield
      end
    end
  end


end
