RSpec::Matchers.define :be_page_for do |klass|
  match do |page|
    meta = page.locator("meta[name='class']")
    expect(meta).to have_attribute("content", klass.name)
  end
  failure_message do |page|
    meta = page.locator("meta[name='class']")
    if meta.count == 0
      "Could not find <meta name='class'> on the page, which is what's needed to know what page we are on:\n\n#{page.content}"
    else
      page_name = meta.get_attribute("content")
      "Expected to be on page #{klass.name}, but we seem to be on page #{page_name}, based on this meta tag:\n\n#{meta.evaluate('e => e.outerHTML')}"
    end
  end
end
