RSpec::Matchers.define :have_rendered do
  match do |result|
    result.kind_of?(String) || result.kind_of?(Brut::FrontEnd::Templates::HTMLSafeString)
  end

  failure_message do |result|
    case result
    in URI => uri
      "Got a redirect to #{uri} instead of rendering"
    in Brut::FrontEnd::HttpStatus => http_status
      "Got an HTTP status of #{http_status} instead of rendering"
    else
      "Got an unexpected result: #{result.class} instead of a String"
    end
  end
  failure_message_when_negated do |result|
    "Result was rendered HTML instead of something else"
  end

end
