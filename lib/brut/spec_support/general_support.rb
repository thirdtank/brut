# Convienience methods included in all tests.
module Brut::SpecSupport::GeneralSupport
  def self.included(mod)
    mod.extend(ClassMethods)
  end

  module ClassMethods
    # To pass bin/test audit with a class whose implementation is trivial, call this inside the RSpec `describe` block. This is better
    # than an empty test as it makes it more explicit that you believe the implementation is trivial enough to not require a test. You
    # can also set an expiration for this thinking.
    #
    # @param [Time|String] check_again_at if given, this will cause the test to fail after the given date/time.  If passed as a
    #                                     string, `Date.parse` is used to convert it to a `Time`.
    def implementation_is_trivial(check_again_at: nil)
      check_again_at = if check_again_at.nil?
                         nil
                       elsif check_again_at.kind_of?(Time)
                         check_again_at
                       else
                         check_again_at = Date.parse(check_again_at).to_time
                       end
      it "has no tests because the implementation is trivial#{check_again_at.nil? ? '' : ' for now'}" do
        if check_again_at.nil?
          expect(true).to eq(true)
        else
          expect(Time.now < check_again_at).to eq(true),"I'ts after #{check_again_at}. Check that the implementation of the class under test is still trivial. If it is, update or remove check_again_at:"
        end
      end
    end

    # Used when a class' implmentation is covered by other tests. This is better than omitting the test or having a blank one, as it
    # makes it explicit that some other test covers this class' behavior.
    #
    # @param [String] description An explanation of what other tests cover this class' implementation.
    def implementation_is_covered_by_other_tests(description)
      it "has no tests because the implementation is sufficiently covered by other tests: #{description}" do
        expect(true).to eq(true)
      end
    end
  end
end
