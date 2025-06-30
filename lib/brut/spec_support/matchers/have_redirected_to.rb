# Page
RSpec::Matchers.define :have_redirected_to do |page_or_uri,**page_params|
  match do |result|
    if page_or_uri.kind_of?(URI)
      if !page_params.empty?
        raise "have_redirected_to, when given a URI, must NOT be given parameters. Got  '#{page_params}'"
      end
      result == page_or_uri
    elsif page_or_uri.ancestors.include?(Brut::FrontEnd::Page)
      result == page_or_uri.routing(**page_params)
    else
      raise "have_redirected_to must be given a URI or a Brut::FrontEnd::Page class, got #{page_or_uri.class}"
    end
  rescue Brut::Framework::Errors::MissingParameter => ex
    raise "#{page_or_uri}'s routing requires parameters you must specicfy to `have_redirected_to`: #{ex.message}"
  end

  failure_message do |result|
    if page_or_uri.kind_of?(URI)
      "Expected #{page_or_uri} but got #{result}"
    elsif page_or_uri.ancestors.include?(Brut::FrontEnd::Page)
      result_explanation = case result
                           when Brut::FrontEnd::Page
                             "#{result.page_name} was rendered directly"
                           when Brut::FrontEnd::HttpStatus
                             "got HTTP status code #{result}"
                           when URI
                             "got a redirect to #{result} instead"
                           else
                             "got a #{result.class} instead"
                           end
      "Expected redirect to #{page_or_uri}, but #{result_explanation}"
    else
      "Unknown error occured or bug with have_redirected_to"
    end
  end
  failure_message_when_negated do |result|
    "Got a redirect when it wasn't expected"
  end
end

# Used on handler specs to check that a response has
# redirected to a page or URI.  Can also be used
# with {Brut::SpecSupport::ComponentSupport#generate_result} to 
# check that a Page's {Brut::FrontEnd::Page#before_generate} method
# did what you expect
#
# @example
#   result = handler.handle
#   expect(result).to have_redirected_to(HomePage)
#
# @example with parameters
#   result = handler.handle
#   expect(result).to have_redirected_to(WidgetsByWidgetIdPage, id: widget.id)
#
# @example arbitrary URI
#   result = handler.handle
#   expect(result).to have_redirected_to("http://kagi.com")
#
# @example testing a `before_generate` method
#   result = generate_result(page)
#   expect(result).to have_redirected_to(LoginPage)
class Brut::SpecSupport::Matchers::HaveRedirectedTo
end
