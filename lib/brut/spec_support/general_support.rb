module Brut::SpecSupport::GeneralSupport
  def self.included(mod)
    mod.extend(ClassMethods)
  end

  module ClassMethods
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
    def implementation_is_covered_by_other_tests(description)
      it "has no tests because the implementation is sufficiently covered by other tests: #{description}" do
        expect(true).to eq(true)
      end
    end
  end
end
