module Sequel
  module Extensions
    module BrutInstrumentation
      class Event < Brut::Instrumentation::Event
        def initialize(sql:nil)
          super(category: "sequel", name: "query", details: { sql: sql })
        end
      end
      def log_connection_yield(sql,conn,args=nil)
        Brut.container.instrumentation.instrument(Event.new(sql: sql)) do
          super
        end
      end
    end
  end
  Sequel::Dataset.register_extension(:brut_instrumentation, Sequel::Extensions::BrutInstrumentation)
  Sequel::Database.register_extension(:brut_instrumentation, Sequel::Extensions::BrutInstrumentation)
end
