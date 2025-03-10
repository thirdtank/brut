# Sets content security policy headers that forbid inline scripts and inline styles.
#
# @see Brut::FrontEnd::RouteHooks::CSPNoInlineScripts
# @see https://developer.mozilla.org/en-US/docs/Web/HTTP/CSP
class Brut::FrontEnd::RouteHooks::CSPNoInlineStylesOrScripts < Brut::FrontEnd::RouteHook
  def after(response:)
    response.headers["Content-Security-Policy"] = header_value
    continue
  end

  # TODO: A way for app to pass in stuff to modify this in part.
  # In particular a hash for a <style>, calculated as follows:
  # - textContent is sha265'ed
  # - that is Base64'ed
  # - that is put as 'sha256–«base64edvalue»` into the directive

  # Sets content security policy headers that only report the use inline scripts and inline styles, but do allow them.
  # This is useful for existing apps where you want to migrate to a more secure policy, but cannot.
  # @see Brut::FrontEnd::Handlers::CspReportingHandler
  class ReportOnly < Brut::FrontEnd::RouteHooks::CSPNoInlineStylesOrScripts
    def after(response:,request:)
      csp_reporting_path   = uri(Brut::FrontEnd::Handlers::CspReportingHandler.routing,request:)
      reporting_directives = "report-to csp_reporting;report-uri #{csp_reporting_path}"

      response.headers["Content-Security-Policy-Report-Only"] = header_value + ";" + reporting_directives
      response.headers["Reporting-Endpoints"]                 = "csp_reporting='#{csp_reporting_path}'"

      continue
    end
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
      "style-src-attr 'none'",
    ].join("; ")
  end


  def uri(path,request:)
    # Adapted from Sinatra's innards
    host = "http#{'s' if request.secure?}://"
    if request.forwarded? || (request.port != (request.secure? ? 443 : 80))
      host << request.host_with_port
    else
      host << request.host
    end
    uri_parts = [
      host,
      request.script_name.to_s,
      path,
    ]
    File.join(uri_parts)
  end
end
