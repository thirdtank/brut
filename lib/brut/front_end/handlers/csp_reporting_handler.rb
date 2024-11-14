class Brut::FrontEnd::Handlers::CspReportingHandler < Brut::FrontEnd::Handler
  def handle(body:)
    begin
      parsed = JSON.parse(body.read)
      SemanticLogger["brut:__brut/csp-reporting"].info(parsed)
    rescue => ex
      SemanticLogger["brut:__brut/locale"].warn("Got #{ex} from /__brut/locale instead of a parseable JSON object")
    end
    http_status(200)
  end
end
