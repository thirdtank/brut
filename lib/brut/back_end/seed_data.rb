require_relative "../factory_bot"
module Brut
  module BackEnd
    # Base class and manager of Seed Data for the app.  Seed Data is data used for development. It is not for populating e.g.
    # reference data or other stuff in production.
    #
    # Seed Data uses FactoryBot.
    class SeedData
      def self.inherited(seed_data_klass)
        @classes ||= []
        @classes << seed_data_klass
      end
      def self.classes = @classes || []

      def setup!
        Brut::FactoryBot.new.setup!
      end

      def load_seeds!
        DB.transaction do
          self.class.classes.each do |klass|
            klass.new.seed!
          end
        end
      end
    end
  end
end
