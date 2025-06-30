# Handler
RSpec::Matchers.define :have_generated do |component_or_page|
  match do |result|
    result.class.ancestors.include?(component_or_page)
  end

  failure_message do |result|
    "Expected a #{component_or_page} to be generated, but got #{result}"
  end
  failure_message_when_negated do |result|
    "Got #{component_or_page} when not expected"
  end

end

# Matcher to check that a handler generated a specific page
# (as opposed to redirected to a page). This works for components
# as well, in the case of Ajax requests.
#
# @example
#   result = handler.handle(form:)
#   expect(result).to have_generated(NewWidgetPage)
#
# @example Ajax request
#   result = handler.handle(form:, xhr: true)
#   expect(result).to have_generated(WidgetResponseComponent)
class Brut::SpecSupport::Matchers::HaveGenerated
end
