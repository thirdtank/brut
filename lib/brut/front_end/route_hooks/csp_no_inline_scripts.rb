class Brut::FrontEnd::RouteHooks::CSPNoInlineScripts < Brut::FrontEnd::RouteHook
  def after(response:)
    response.headers["Content-Security-Policy"] = header_value
    continue
  end

  def header_value
    [
      "default-src 'self'",
      "script-src-elem 'self'",
      "script-src-attr 'none'",
      "style-src-elem 'self'",
      "style-src-attr 'self'",
    ].join("; ")
  end

end
