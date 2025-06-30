RSpec::Matchers.define :have_returned_http_status do |http_status=nil|
  match do |result|
    if http_status.nil?
      result.kind_of?(Brut::FrontEnd::HttpStatus)
    else
      case result
      in URI => uri
        http_status == 302
      in Brut::FrontEnd::HttpStatus => result_http_status
        http_status == result_http_status.to_i
      else
        http_status == 200
      end
    end
  end

  failure_message do |result|
    case result
    in URI => uri
      "Got a redirect (302) instead of a #{http_status}"
    in Brut::FrontEnd::HttpStatus => result_http_status
      "Got a #{result_http_status} instead of a #{http_status}"
    else
      "Got a render (200) instead of a #{http_status}"
    end
  end
  failure_message_when_negated do |result|
    if http_status.nil?
      "#{result} was rendered, but was not expecting an HTTP status"
    else
      "Got #{http_status} when not expected (#{result.class} was returned)"
    end
  end
end

# Used on handler specs to check that a response returned
# a particular HTTP status code. Can also be used
# with {Brut::SpecSupport::ComponentSupport#generate_result} to 
# check that a Page's {Brut::FrontEnd::Page#before_generate} method
# did what you expect
#
# @example
#   result = handler.handle
#   expect(result).to have_returned_http_status(404)
#
# @example dont' care what status, just that one was returned instead of a page generation
#   result = handler.handle
#   expect(result).to have_returned_http_status
#
#
# @example testing a `before_generate` method
#   result = generate_result(page)
#   expect(result).to have_returned_http_status(403)
class Brut::SpecSupport::Matchers::HaveReturnedHttpStatus
end
