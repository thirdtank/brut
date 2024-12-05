module Sequel
  module Extensions
    # Modifies and enhances Sequel's migrations DSL to default to best practices.
    #
    # * If no primary key is specified, a primary key column named `id` of type `int` will be created.
    # * If no `created_at` is specified, a column name `created_at` of type `timestamptz` is created.
    # * `create_table` requires a `comment:` attribute that explains the purpose of the table.
    # * `create_table` accepts an `external_id: true` attribute that will create a unique `citext` field named `external_id`. This is intended to be used with {Sequel::Plugins::ExternalId}.
    # * Columns are non-null by default. To make a nullable column, use `null: true`.
    # * Foreign keys are non-null by default and an index is created by default.
    # * The `key` method allows specifying additional keys on the table. This effecitvely creates a unique constraint on the fields given to `key`.
    module BrutMigrations
      # Overrides Sequel's `create_table`
      #
      # @param args [Object] the arguments to pass to Sequel's `create_table`.  If the last entry in `*args` is a `Hash`, new options are recognized:
      # @option args [String] :comment String containing the table's description, included in the table definition. Required.
      # @option args [true|false] :external_id If true, adds a `:citext` column named `external_id` that has a unique index on it.
      def create_table(*args)
        super

        if args.last.is_a?(Hash)
          if args.last[:comment]
            run %{
              comment on table #{args.first} is #{literal args.last[:comment]}
            }
          else
            raise ArgumentError, "Table #{args.first} must have a comment"
          end
          if args.last[:external_id]
            add_column args.first, :external_id, :citext, unique: true
          end
        end
      end

      # Specifies a non-primary key based on the fields given. Effectively creates a unique index on these fields.
      # Inside a `create_table` block, this can be called via `key`
      #
      # @param fields [Array] fields that should form the key.
      def add_key(fields)
        add_index fields, unique: true
      end

      # Overrides Sequel's `add_column` to default `null: false`.
      def add_column(table,*args)
        options = args.last
        if options.is_a?(Hash)
          if !options.key?(:null)
            options[:null] = false
          end
        end
        super(table,*args)
      end

      def create_table_from_generator(name, generator, options)
        if name != "schema_migrations"
          if generator.columns.none? { |column| column[:primary_key] }
            generator.primary_key :id
          end
          if generator.columns.none? { |column| column[:name].to_s == "created_at" }
            generator.column :created_at, :timestamptz, null: false
          end
          generator.columns.each do |column|
            if !column.key?(:null)
              column[:null] = false
            end
            if column.key?(:table)
              if !column.key?(:index)
                column[:index] = true
                generator.index(column[:name])
              end
            end
          end
        end
        super
      end
    end
  end
end
Sequel::Database.register_extension(:brut_migrations) do |db|
  db.extend Sequel::Extensions::BrutMigrations
  class ::Sequel::Schema::CreateTableGenerator
    def key(fields)
      index fields, unique: true
    end
  end
  class ::Sequel::Schema::AlterTableGenerator
    def add_column_with_additions(name, type, opts={})
      if !opts.key?(:null)
        opts[:null] = false
      end
      add_column_base(name,type,opts)
    end
    alias_method :add_column_base, :add_column
    alias_method :add_column, :add_column_with_additions

    def add_foreign_key_with_additions(name, table, opts={})
      if !opts.key?(:index)
        opts[:index] = true
      end
      if !opts.key?(:null)
        opts[:null] = false
      end
      add_foreign_key_base(name, table, opts)
    end
    alias_method :add_foreign_key_base, :add_foreign_key
    alias_method :add_foreign_key, :add_foreign_key_with_additions
  end
end
