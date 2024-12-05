module Sequel
  module Extensions
    # Instruments all SQL executions.
    module BrutInstrumentation
      # The event used to instrument SQL statements.  It includes the SQL statement.
      class Event < Brut::Instrumentation::Event
        def initialize(sql:nil)
          super(category: "sequel", name: "query", details: { sql: sql })
        end
      end
      # @!visibility private
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
