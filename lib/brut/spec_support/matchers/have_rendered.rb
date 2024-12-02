RSpec::Matchers.define :have_rendered do |component_or_page|
  match do |result|
    result.class.ancestors.include?(component_or_page)
  end

  failure_message do |result|
    "Expected a #{component_or_page} to be rendered, but got #{result}"
  end
  failure_message_when_negated do |result|
    "Got #{component_or_page} when not expected"
  end

end
