# Receives content security policy violations and logs them. This is set up in {Brut::Framework::MCP}, however CSP reporting is
# configured in {Brut::FrontEnd::RouteHooks::CSPNoInlineStylesOrScripts::ReportOnly}.
class Brut::FrontEnd::Handlers::CspReportingHandler < Brut::FrontEnd::Handler
  def handle(body:)
    begin
      parsed = JSON.parse(body.read)
      SemanticLogger[self.class].info(parsed)
    rescue => ex
      SemanticLogger[self.class].warn("Got #{ex} instead of a parseable JSON object")
    end
    http_status(200)
  end
end
