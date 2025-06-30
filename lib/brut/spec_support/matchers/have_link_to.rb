# Component/Page
RSpec::Matchers.define :have_link_to do |page_klass,**args|
  match do |node|
    node.css("a[href='#{page_klass.routing(**args)}']").any?
  end

  failure_message do |node|
    links = node.css("a").map(&:to_html)
    "Did not find link to #{page_klass.routing(**args)}. Found these links: #{links.join(',')}"
  end

  failure_message_when_negated do |result|
    "Did not expect to find link to #{page_klass.routing(**args)}."
  end
end

# Used on a component/page spec to check that there is a link
# to a specific routing.  This handles creating a CSS selector
# like `[href="#{page_klass.routing(**args)}"]`.
#
# @example
#   result = generate_and_parse(page)
#   expect(result.e!("nav")).to have_link_to(HomePage)
#
# @example link with parameters
#   result = generate_and_parse(page)
#   expect(result.e!("nav")).to have_link_to(WidgetsByWidgetIdPage, id: widget.id)
#
class Brut::SpecSupport::Matchers::HaveLinkTo
end
