module Sequel
  module Extensions
    # Enhancements to migrations to encourage better practices and reduce boilerplate.
    #
    # * If no primary key is specified, a primary key column named :id of type :int will be created
    # * If no created_at is specified, a column name created_at of type timestamptz is created
    # * create_table requires a comment: field
    # * create_table accepts an external_id: true option that will create a unique citext called "external_id"
    # * columns are non-null by default
    # * foreign keys are non-null and an index is created
    # * the `key` method allows specifying keys aka creating a unique constraint
    module BrutMigrations
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

      def add_key(fields)
        add_index fields, unique: true
      end

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
