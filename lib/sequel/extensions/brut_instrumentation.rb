module Sequel
  module Extensions
    # Instruments all SQL executions.
    module BrutInstrumentation
      # @!visibility private
      def log_connection_yield(sql,conn,args=nil)
        Brut.container.instrumentation.span("SQL", sql: sql) do |span|
          super
        end
      end
    end
  end
  Sequel::Dataset.register_extension(:brut_instrumentation, Sequel::Extensions::BrutInstrumentation)
  Sequel::Database.register_extension(:brut_instrumentation, Sequel::Extensions::BrutInstrumentation)
end
