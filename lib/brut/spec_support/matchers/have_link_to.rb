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
