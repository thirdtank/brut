RSpec::Matchers.define :be_a_bug do
  match(:notify_expectation_failures => true) do |actual|
    exception = nil
    begin
      actual.call
    rescue => ex
      exception = ex
    end
    expect(exception).not_to eq(nil),"Expected a bug, but no exception was thrown"
    expect(exception).to be_kind_of(Brut::Framework::Errors::Bug)
  end

  supports_block_expectations
end

# Block-based matcher that expects the blog to 
# raise a {Brut::Framework::Errors::Bug}.
#
# @example
#   expect {
#     SomeClass.new(value: :invalid)
#   }.to be_a_bug
#
class Brut::SpecSupport::Matchers::BeABug
end
