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
    x = "sha256-d21f9b773d3cfad25f041a96ab08376e944e9ad4843f2060ecbdbefb12d91b1d"
    x = "sha256-0h+bdz08+tJfBBqWqwg3bpROmtSEPyBg7L2++xLZGx0="
    [
      "default-src 'self'",
      "script-src-elem 'self'",
      "script-src-attr 'none'",
      "style-src-elem 'self'",
      "style-src-attr 'self'",
    ].join("; ")
  end

end
