RSpec::Matchers.define :have_constraint_violation do |key|
  match do |validity_state|
    key = key.to_s
    validity_state.any? do |constraint_violation|
      constraint_violation.key == key
    end
  end

  failure_message do |validity_state|
    keys_with_violations = validity_state.map { it.key }

    if keys_with_violations.any?
      "Did not find a violation for '#{key}', but found these keys with violations: #{keys_with_violations.join(", ")}"
    else
      "Did not find any constraint violations"
    end
  end

  failure_message_when_negated do |validity_state|
    "Found #{key} as a violation when not expecting it"
  end
end

