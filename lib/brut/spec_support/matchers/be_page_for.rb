RSpec::Matchers.define :be_page_for do |klass|
  match do |page|
    meta = page.locator("meta[name='class']")
    expect(meta).to have_attribute("content", klass.name)
  end
  failure_message do |page|
    meta = page.locator("meta[name='class']")
    if meta.count == 0
      "Could not find <meta name='class'> on the page:\n\n#{page.content}"
    else
      "Could not find <meta name='class' content='#{klass.name}'>, but found:\n\n#{meta.evaluate('e => e.outerHTML')}"
    end
  end
end
