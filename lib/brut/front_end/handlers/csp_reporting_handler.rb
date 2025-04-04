# Receives content security policy violations and logs them. This is set up in {Brut::Framework::MCP}, however CSP reporting is
# configured in {Brut::FrontEnd::RouteHooks::CSPNoInlineStylesOrScripts::ReportOnly}.
class Brut::FrontEnd::Handlers::CspReportingHandler < Brut::FrontEnd::Handler
  def handle(body:)
    begin
      parsed = JSON.parse(body.read)
      Brut.container.instrumentation.add_attributes(parsed.merge(prefix: "brut.csp-reporting"))
    rescue => ex
      Brut.container.instrumentation.record_exception(ex)
    end
    http_status(200)
  end
end
