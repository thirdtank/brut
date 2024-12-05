# Sets content security policy headers that forbid inline scripts and inline styles.
#
# @see Brut::FrontEnd::RouteHooks::CSPNoInlineScripts
# @see https://developer.mozilla.org/en-US/docs/Web/HTTP/CSP
class Brut::FrontEnd::RouteHooks::CSPNoInlineStylesOrScripts < Brut::FrontEnd::RouteHook
  def after(response:)
    response.headers["Content-Security-Policy"] = header_value
    continue
  end

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
