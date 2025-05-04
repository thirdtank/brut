# Handler
RSpec::Matchers.define :have_returned_rack_response do |http_status: :any, headers: :any, body: :any|
  match do |result|
    case result
    in [ response_status, response_headers, response_body ]
      http_status_match = http_status == :any || response_status == http_status
      headers_match     = headers == :any || response_headers == headers
      body_match        = body == :any || response_body == body

      http_status_match && headers_match && body_match
    else
      false
    end
  end

  failure_message do |result|
    case result
    in [ response_status, response_headers, response_body ]
      http_status_match = http_status == :any || response_status == http_status
      headers_match     = headers == :any || response_headers == headers
      body_match        = body == :any || response_body == body
      errors = [
        http_status_match ? nil : "HTTP status #{response_status} did not match #{http_status}",
        headers_match     ? nil : "Headers #{response_headers} did not match #{headers}",
        body_match        ? nil : "Body #{response_body} did not match #{body}",
      ].compact.join(", ")
    else
      if result.kind_of?(Array)
        "Response was a #{result.class} of length #{result.length}, which could not be interpreted as a Rack response."
      else
        "Response was a #{result.class}, which could not be interpreted as a Rack response."
      end
    end
  end
  failure_message_when_negated do |result|
    case result
    in [ response_status, response_headers, response_body ]
      "Response was a Rack response and/or array of size 3"
    else
      "failure_message_when_negated encounterd a code-path for a non-Rack response, which should not have happened when have_returned_rack_response was negated"
    end
  end

end
