RSpec::Matchers.define :be_routing_for do |klass,**args|
  match do |uri|
    uri == Brut.container.routing.uri(klass,**args)
  end

  failure_message do |uri|
    expected = Brut.container.routing.uri(klass,**args)
    "Expected route for #{klass}: #{expected}, but got #{uri}"
  end

end
