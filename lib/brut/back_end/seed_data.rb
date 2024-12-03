require_relative "../factory_bot"
module Brut
  module BackEnd
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
