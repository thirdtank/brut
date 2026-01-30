require "brut/back_end/seed_data"
class SeedData < Brut::BackEnd::SeedData
  include FactoryBot::Syntax::Methods
  def seed!
    # Create records here.  This method is not expected
    # to be idempotent.  You can (and should) use your 
    # FactoryBot factories here.
  end
end
