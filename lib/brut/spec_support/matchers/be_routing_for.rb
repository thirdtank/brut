RSpec::Matchers.define :be_routing_for do |klass,**args|
  match do |uri|
    uri == Brut.container.routing.path(klass,**args)
  end

  failure_message do |uri|
    expected = Brut.container.routing.path(klass,**args)
    "Expected route for #{klass}: #{expected}, but got #{uri}"
  end

end

# Matcher used for handlers (or any code that returns a `URI`)
# to assert that the URI is for a given page with the given set of parameters
#
# @example
#   result = handler.handle
#   expect(result).to be_routing_for(HomePage)
#
# @example with parameters
#   result = handler.handle
#   expect(result).to be_routing_for(WidgetsByWidgetIdPage, id: widget.external_id)
#
# @example with anchor
#   result = handler.handle
#   expect(result).to be_routing_for(MessagesPage, anchor: "latest_message")
#
class Brut::SpecSupport::Matchers::BeRoutingFor
end
