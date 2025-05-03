require_relative "../factory_bot"
module Brut
  module BackEnd
    # Base class and manager of Seed Data for the app.  Seed Data is data used for development.
    # It is not for populating e.g. reference data or other stuff in production, nor is it for
    # managing test data.
    #
    # Seed Data uses FactoryBot.
    #
    # To create your own seed data:
    #
    # 1. Inherit from this class.  Doing so will register your class with an internal data structure
    #    Brut will use to create all seed data.
    # 2. Provide a no-arg initializer (although you are unlikely to need any initializer at all).
    # 3. Implement {#seed!} to use Factory Bot to create all the seed data.  This method should be self-contained
    #    and not rely on other seed data classes.  It need not be idempotent.
    class SeedData
      def self.inherited(seed_data_klass)
        @classes ||= []
        @classes << seed_data_klass
      end
      def self.classes = @classes || []

      # Sets up anything needed before seed data can be created. Do not override this method.
      def setup!
        Brut::FactoryBot.new.setup!
      end

      # Loads all seed data registered with this class.  Seed data is registered when a class
      # extends this one.  Do not override this method.
      def load_seeds!
        DB.transaction do
          self.class.classes.each do |klass|
            klass.new.seed!
          end
        end
      end

      # Implement this to create your seed data.
      def seed!
        raise Brut::Framework::Errors::AbstractMethod
      end
    end
  end
end
