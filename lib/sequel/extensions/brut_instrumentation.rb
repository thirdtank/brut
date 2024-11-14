module Sequel
  module Extensions
    module BrutInstrumentation
      class Event < Brut::Instrumentation::Event
        def initialize(operation:,sql:nil)
          super(category: "sequel", name: operation, details: { sql: sql })
        end
      end
      def execute(sql, opts = Sequel::OPTS, &block)
        Brut.container.instrumentation.instrument(Event.new(operation: "execute", sql: sql)) do
          super
        end
      end
      def execute_dui(sql, opts = Sequel::OPTS, &block)
        Brut.container.instrumentation.instrument(Event.new(operation: "execute_dui", sql: sql)) do
          super
        end
      end
      def execute_insert(sql, opts = Sequel::OPTS, &block)
        Brut.container.instrumentation.instrument(Event.new(operation: "execute_insert", sql: sql)) do
          super
        end
      end
      def insert_select(*values)
        Brut.container.instrumentation.instrument(Event.new(operation: "insert_select", sql: values)) do
          super
        end
      end
      def returning_fetch_rows(sql,&block)
        Brut.container.instrumentation.instrument(Event.new(operation: "returning_fetch_rows", sql: sql)) do
          super
        end
      end
    end
  end
  Sequel::Dataset.register_extension(:brut_instrumentation, Sequel::Extensions::BrutInstrumentation)
end
