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
      "Expected #{page_or_uri}'s routing (#{page_or_uri.routing(**page_params)}), but got #{result}"
    else
      "Unknown error occured or bug with have_redirected_to"
    end
  end
  failure_message_when_negated do |result|
    "Got a redirect when it wasn't expected"
  end

end
