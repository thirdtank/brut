require "brut"
require "confidence_check/for_rspec"

require_relative "support"

RSpec.configure do |config|
  config.include ConfidenceCheck::ForRSpec

  config.expect_with :rspec do |expectations|
    expectations.include_chain_clauses_in_custom_matcher_descriptions = true
  end

  config.mock_with :rspec do |mocks|
    mocks.verify_partial_doubles = true
  end

  config.shared_context_metadata_behavior = :apply_to_host_groups

  config.filter_run_when_matching :focus
  config.disable_monkey_patching!
  config.warnings = ENV["RSPEC_WARNINGS"] == "true"

  if config.files_to_run.one?
    config.default_formatter = "doc"
  end

  config.profile_examples = (ENV["RSPEC_PROFILE_EXAMPLES"] || "0").to_i

  config.order = :random
  Kernel.srand config.seed
end
