ENV["RACK_ENV"] = "test"
require_relative "../app/bootstrap"
Bootstrap.new.bootstrap!

require "brut/spec_support"

require "nokogiri"
require "playwright"
require "playwright/test"
require "confidence_check/for_rspec"
require "with_clues"

require_relative "support"

RSpec.configure do |config|
  # This configuration has two main parts.
  #
  # The first part is here: a call to Brut::SpecSupport::RSpecSetup,
  # which will set configuration values required for Brut's spec
  # helpers and other APIs. In generally, you do not want to change
  # this configuration.
  rspec_setup = Brut::SpecSupport::RSpecSetup.new(rspec_config: config)
  rspec_setup.setup!

  # The second part is here and is RSpec configuration that you may want
  # to change. Changing the configuration below here should not break
  # any of Brut's internal behavior around tests.  The values
  # and configuration options set are a recommended default, but you
  # can certainly change it to suit your needs.


  # Confidence Check allows you to wrap test expectations
  # with confidence_check as a way to indicate those expectations are
  # checking that the test is setup properly and not testing
  # the behavior of the code under test
  config.include ConfidenceCheck::ForRSpec

  # With Clues allows you to wrap expectations in 
  # a with_clues block that will provide more details
  # about the failure and make it easier to diagnose 
  # why a test failed.
  config.include WithClues::Method
  config.include FactoryBot::Syntax::Methods

  config.expect_with :rspec do |expectations|
    expectations.include_chain_clauses_in_custom_matcher_descriptions = true
  end

  config.mock_with :rspec do |mocks|
    mocks.verify_partial_doubles = true
  end

  # Not that you should be using shared contexts, but if you are, please
  # see https://rubydoc.info/gems/rspec-core/3.13.5/RSpec/Core/Configuration#shared_context_metadata_behavior-instance_method
  config.shared_context_metadata_behavior = :apply_to_host_groups

  config.filter_run_when_matching :focus

  # Can't find docs on how this path is resolved, so disabling
  # config.example_status_persistence_file_path = "spec/examples.txt"

  config.disable_monkey_patching!

  config.warnings = ENV.fetch("RSPEC_WARNINGS","false") == "true"

  if config.files_to_run.one?
    config.default_formatter = "doc"
  end

  if ENV["RSPEC_PROFILE_EXAMPLES"]
    config.profile_examples = ENV["RSPEC_PROFILE_EXAMPLES"].to_i
  end

  config.order = :random

  Kernel.srand config.seed
end

