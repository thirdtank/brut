class Brut::FrontEnd::Middlewares::OpenTelemetrySpan < Brut::FrontEnd::Middleware
  def initialize(app)
    @app = app
  end
  def call(env)
    otel_standard_attributes = {
      "http.request.method"      => env["REQUEST_METHOD"],
      "url.path"                 => env["PATH_INFO"],
      "url.query"                => env["QUERY_STRING"],
      "url.scheme"               => env["rack.url_scheme"],
      "url.full"                 => "#{env["rack.url_scheme"]}://#{env["HTTP_HOST"]}#{env["REQUEST_URI"]}",
      "server.address"           => env["HTTP_HOST"],
      "user_agent.original"      => env["HTTP_USER_AGENT"],
      "network.peer.ip"          => env["REMOTE_ADDR"],
      "network.peer.port"        => env["REMOTE_PORT"],
      "network.protocol.version" => env["HTTP_VERSION"],
    }.merge(
      "http.request.header.accept-language" => env["HTTP_ACCEPT_LANGUAGE"],
      "http.request.header.referer"         => env["HTTP_REFERER"],
      "http.request.header.user-agent"      => env["HTTP_USER_AGENT"],
      "http.request.header.accept"          => env["HTTP_ACCEPT"],
    ).delete_if { |_,v| v.nil? || v.empty? }

    span_name = if env["PATH_INFO"] =~ /^\/js\//
                  "HTTP #{env['REQUEST_METHOD']} JS"
                elsif env["PATH_INFO"] =~ /^\/css\//
                  "HTTP #{env['REQUEST_METHOD']} CSS"
                else
                  "HTTP #{env['REQUEST_METHOD']}"
                end
    Brut.container.tracer.in_span(span_name,kind: :server, attributes: otel_standard_attributes) do |span|
      env["brut.otel.root_span"] = span
      @app.call(env)
    end
  end
end
