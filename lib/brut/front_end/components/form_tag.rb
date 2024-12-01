require "rexml"
# Represents a <form> HTML component
class Brut::FrontEnd::Components::FormTag < Brut::FrontEnd::Component
  def initialize(**attributes,&contents)
    form_class = attributes.delete(:for)
    if !form_class.nil?
      if attributes[:action]
        raise ArgumentError, "You cannot specify both for: (#{form_class}) and and action: (#{attributes[:action]}) to a form_tag"
      end
      if attributes[:method]
        raise ArgumentError, "You cannot specify both for: (#{form_class}) and and method: (#{attributes[:method]}) to a form_tag"
      end
      if form_class.kind_of?(Brut::FrontEnd::Form)
        form_class = form_class.class
      end
      route = Brut.container.routing.route(form_class)
      attributes[:method] = route.http_method
      attributes[:action] = route.path
    end

    @include_csrf_token = true
    @csrf_token_omit_reasoning = nil

    http_method = Brut::FrontEnd::HttpMethod.new(attributes[:method])

    if http_method.get?
      if attributes.key?(:no_csrf_token)
        raise ArgumentError,":no_csrf_token is not allowed for form_tag when the HTTP method is a GET"
      end
      force_csrf_token = attributes.delete(:force_csrf_token)
      if !force_csrf_token
        @include_csrf_token = false
        @csrf_token_omit_reasoning = "because this form's action is GET"
      end
    else
      if attributes.key?(:force_csrf_token)
        raise ArgumentError,":force_csrf_token is not allowed for form_tag when the HTTP method is not a GET"
      end
      no_csrf_token = attributes.delete(:no_csrf_token)
      if no_csrf_token
        @include_csrf_token = false
        @csrf_token_omit_reasoning = "because :no_csrf_token was passed to form_tag"
      end
    end
    @attributes = attributes
    @contents = contents
  end

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
