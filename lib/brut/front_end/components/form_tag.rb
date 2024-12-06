require "rexml"
# Represents a `<form>` HTML element that includes a CSRF token as needed. You likely want to use this class via the {Brut::FrontEnd::Component::Helpers#form_tag} method.
class Brut::FrontEnd::Components::FormTag < Brut::FrontEnd::Component
  # (see Brut::FrontEnd::Component::Helpers#form_tag)
  def initialize(route_params: {}, **html_attributes,&contents)
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
    @attributes = html_attributes
    @contents = contents
  end

  # @!visibility private
  def render
    attribute_string = @attributes.map { |key,value|
      key = key.to_s
      if value == true
        key
      elsif value == false
        ""
      else
        REXML::Attribute.new(key,value).to_string
      end
    }.join(" ")
    csrf_token_component = if @include_csrf_token
                             component(Brut::FrontEnd::Components::Inputs::CsrfToken)
                           elsif Brut.container.project_env.development?
                             html_safe!("<!-- CSRF Token omitted #{@csrf_token_omit_reasoning} (this message only appears in development) -->")
                           else
                             ""
                           end
    %{
      <form #{attribute_string}>
        #{ csrf_token_component }
        #{ @contents.() }
      </form>
    }
  end
end
