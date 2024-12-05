# Sets content security policy headers that forbid inline scripts, but allow inline styles.
# This is intended to be used in development to allow easier UI design work to happen in the browser
# by the temporary use of inline styles.
#
# @see Brut::FrontEnd::RouteHooks::CSPNoInlineStylesOrScripts
# @see https://developer.mozilla.org/en-US/docs/Web/HTTP/CSP
class Brut::FrontEnd::RouteHooks::CSPNoInlineScripts < Brut::FrontEnd::RouteHook
  def after(response:)
    response.headers["Content-Security-Policy"] = header_value
    continue
  end

private

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
