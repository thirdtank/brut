# E2E
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

# Matcher for end-to-end tests to assert that the current page
# is the page you expect it to be.  This is based on the
# {Brut::FrontEnd::Components::PageIdentifier} component, which must
# be included on the page for this matcher to work.
#
# @example
#   expect(page).to be_page_for(HomePage)
class Brut::SpecSupport::Matchers::BePageFor
end
