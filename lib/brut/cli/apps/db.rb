require "sequel"
require "uri"
require "date"
require "brut/cli"

class Brut::CLI::Apps::DB < Brut::CLI::Commands::BaseCommand
  def description = "Manage your database in development, test, and production"
  def name = "db"

  class Status < Brut::CLI::Commands::BaseCommand
    def description = "Check the status of the database and migrations"
    def default_rack_env = "development"
    def bootstrap? = false

    def run
      database_name = URI(Brut.container.database_url).path.gsub(/^\//,"")
      connection = Brut.container.sequel_db_handle
      migrations_run = if connection.table_exists?("schema_migrations")
                         connection["select filename from schema_migrations order by filename"].all.map { |_| _[:filename] }
                       else
                         []
                       end
      migration_files = Dir[Brut.container.migrations_dir / "*.rb"].map { |file|
        filename = Pathname(file).basename.to_s
      }
      puts status_table(server_up: true, database_exists: true, database_name:, migrations_run:, migration_files:).render
      0
    rescue Sequel::DatabaseConnectionError => ex
      uri_no_database = URI(Brut.container.database_url.to_s)
      database_name = uri_no_database.path.gsub(/^\//,"")
      uri_no_database.path = ""
      begin
        connection = Sequel.connect(uri_no_database.to_s)
        puts status_table(server_up: true, database_exists: false, database_name:, migrations_run: [], migration_files: []).render
        puts [
          theme.warning.render("Try creating the database with"),
          theme.code.render("brut db create"),
        ].join(" ")
        0
      rescue => ex2
        puts status_table(server_up: false, database_exists: false, database_name:, migrations_run: [], migration_files: []).render
        puts theme.error.render("Database server is not running at #{uri_no_database}: #{ex2.message}")
        puts theme.error.render("This could be a problem with your dev environment generally, or your .env.test or .env.test.local files")
        1
      end
    end

  private

    def status_table(server_up:, database_exists:, database_name:, migrations_run:, migration_files:)
      rows = [
        [
          "Database Server",
          server_up ? theme.success.render("✅ UP") : theme.error.render("❌ DOWN")
        ],
      ]
      if server_up
        rows << [
          "Database #{theme.code.render(database_name)}",
          database_exists ? theme.success.render("✅ Exists") : theme.error.render("❌ DOES NOT EXIST")
        ]
      end
      if database_exists
        if migration_files.empty? && migrations_run.empty?
          rows << [
            "Migrations",
            "✅ NO MIGRATION FILES TO RUN"
          ]
        else
          migration_files.each do |filename|
            applied = if migrations_run.include?(filename)
                        theme.success.render("✅ APPLIED") 
                      else
                        theme.warning.render("❌ NOT APPLIED")
                      end
            rows << [ filename, applied ]
          end
        end
      end
      Lipgloss::Table.new.
        headers([ "Check", "Status" ]).
        rows(rows).
        style_func(rows: rows.length, columns: 2) { |row,column|
          if row == Lipgloss::Table::HEADER_ROW
            Lipgloss::Style.new.inherit(theme.header).padding_left(1).padding_right(1)
          else
            Lipgloss::Style.new.inherit(theme.none).padding_left(1).padding_right(1)
          end
        }
    end

  end

  class Create < Brut::CLI::Commands::BaseCommand
    def description = "Create the database if it does not exist"
    def default_rack_env = "development"
    def bootstrap? = false

    def run
      uri_no_database = URI(Brut.container.database_url.to_s)
      database_name = uri_no_database.path.gsub(/^\//,"")
      uri_no_database.path = ""
      begin
        connection = Sequel.connect(Brut.container.database_url)
        puts [
          theme.success.render("✅ Database"),
          theme.code.render(database_name),
          theme.success.render("already exists"),
        ].join(" ")
        connection.disconnect
        0
      rescue Sequel::DatabaseConnectionError => ex
        begin
          connection = Sequel.connect(uri_no_database.to_s)
          puts [
            "Database",
            theme.code.render(database_name),
            "does not exist. Creating...",
          ].join(" ")
          connection.run("CREATE DATABASE \"#{database_name}\"")
          connection.disconnect
          puts [
            theme.success.render("✅ Database"),
            theme.code.render(database_name),
            theme.success.render("created"),
          ].join(" ")
          0
        rescue Sequel::DatabaseConnectionError => ex2
          puts [
            theme.error.render("Database server is not running at"),
            theme.code.render(uri_no_database.to_s),
          ].join(" ")
          puts [
            theme.error.render(ex2.class.name),
            theme.exception.render(ex2.message),
          ].join(": ")

          puts theme.error.render("This could be a problem with your dev environment")
          puts [
            theme.error.render("Check"),
            theme.code.render(".env.test"),
            theme.error.render("and"),
            theme.code.render(".env.test.local"),
            theme.error.render("to see if "),
            theme.code.render("DATABASE_URL"),
            theme.error.render("is set correctly"),
          ].join(" ")
          1
        end
      end
    end
  end

  class Drop < Brut::CLI::Commands::BaseCommand
    def description = "Drop the database if it exists"
    def default_rack_env = "development"
    def bootstrap? = false

    def run
      uri_no_database = URI(Brut.container.database_url.to_s)
      database_name = uri_no_database.path.gsub(/^\//,"")
      uri_no_database.path = ""
      begin
        Brut.container.sequel_db_handle.disconnect
        puts "Database #{theme.code.render(database_name)} exists. Dropping..."
        connection = Sequel.connect(uri_no_database.to_s)
        connection.run("DROP DATABASE IF EXISTS \"#{database_name}\"")
        connection.disconnect
        puts [
          theme.success.render("✅ Database"),
          theme.code.render(database_name),
          theme.success.render("dropped"),
        ].join(" ")
        0
      rescue Sequel::DatabaseConnectionError => ex
        begin
          connection = Sequel.connect(uri_no_database.to_s)
          puts [
            theme.success.render("✅ Database"),
            theme.code.render(database_name),
            theme.success.render("has already been dropped"),
          ].join(" ")
          connection.disconnect
          0
        rescue Sequel::DatabaseConnectionError => ex2
          puts [
            theme.error.render("Database server is not running at"),
            theme.code.render(uri_no_database.to_s),
          ].join(" ")
          puts [
            theme.error.render(ex2.class.name),
            theme.exception.render(ex2.message),
          ].join(": ")

          puts theme.error.render("This could be a problem with your dev environment")
          puts [
            theme.error.render("Check"),
            theme.code.render(".env.test"),
            theme.error.render("and"),
            theme.code.render(".env.test.local"),
            theme.error.render("to see if "),
            theme.code.render("DATABASE_URL"),
            theme.error.render("is set correctly"),
          ].join(" ")
          1
        end
      end
    end
  end

  class Migrate < Brut::CLI::Commands::BaseCommand
    def description = "Apply any outstanding migrations to the database"
    def default_rack_env = "development"

    class MessagingProxyLogger < SimpleDelegator
      def initialize(logger, command)
        super(logger)
        @command = command
      end
      def info(msg)
        if msg =~ /Finished applying migration (.*).rb/
          @command.send(:puts,"Applied migration #{@command.send(:theme).code.render($1)}")
        end
        __getobj__.info(msg)
      end
    end

    def opts = [
      [ "--[no-]sequel-log", "Log Sequel activity at same level as --log-level. When disabled, Sequel will not log at all." ],
    ]

    def run
      migrations_dir = Brut.container.migrations_dir
      if !migrations_dir.exist?
        puts "No migrations to run from #{migrations_dir}"
        return 0
      elsif Dir[migrations_dir / "*.rb"].empty?
        puts "No migrations to run from #{migrations_dir}"
        return 0
      end

      Sequel.extension :migration
      Brut.container.sequel_db_handle.extension :brut_migrations
      Brut.container.sequel_db_handle.extension :pg_array

      Brut.container.sequel_db_handle.logger = MessagingProxyLogger.new(
        execution_context.logger.without_stderr,
        self
      )
      Sequel::Migrator.run(Brut.container.sequel_db_handle,migrations_dir)
      puts theme.success.render("✅ All migrations have been applied")
      0
    rescue Sequel::DatabaseConnectionError => ex
      database_name = URI(Brut.container.database_url).path.gsub(/^\//,"")
      puts [
        theme.error.render("Database"),
        theme.code.render(database_name),
        theme.error.render("does not exist."),
      ].join(" ")
      puts [
        theme.warning.render("Create it first with"),
        theme.code.render("brut db create"),
      ].join(" ")
      1
    rescue Sequel::DatabaseError => ex
      #if ex.cause.kind_of?(PG::UndefinedTable)
      #  # ignoring - we are running migrations which will address this
      #  0
      #else
        raise ex
      #end
    end
  end

  class Rebuild < Brut::CLI::Commands::CompoundCommand
    def description = "Drop, re-create, and run migrations, effecitvely rebuilding the entire database"
    def default_rack_env = "development"
    def bootstrap? = false
    def initialize
      super([
        Drop.new,
        Create.new,
        Migrate.new,
      ])
    end
  end


  class Seed < Brut::CLI::Commands::BaseCommand
    def description = "Load seed data into the database"
    def default_rack_env = "development"
    def bootstrap? = true

    def run
      seeds_dir = Brut.container.db_seeds_dir
      info "Using seeds from #{seeds_dir}"
      Dir["#{seeds_dir}/*.rb"].each do |file|
        info "Loading seed file #{file}"
        friendly_filename = Pathname(file).relative_path_from(Brut.container.project_root)
        puts "Loading seed data from #{theme.code.render(friendly_filename.to_s)}"
        require file
      end
      seed_data = Brut::BackEnd::SeedData.new
      seed_data.setup!
      seed_data.load_seeds!
      puts theme.success.render("✅ Seed data loaded")
      0
    rescue Sequel::UniqueConstraintViolation => ex
      puts theme.error.render("Seed data may have already been loaded:")
      puts theme.exception.render("  #{ex}".strip)
      puts [
        theme.error.render("You can re-load it using"),
        theme.code.render("brut db rebuild && brut db seed"),
      ].join(" ")
      1
    end
  end

  class NewMigration < Brut::CLI::Commands::BaseCommand
    def description = "Create a new migration file"
    def opts = [
      [ "--dry-run", "If true, only show what would happen, don't make any files" ],
    ]
    def args_description = "migration_name"
    def bootstrap? = false
    def default_rack_env = "development"

    def run
      if argv.length == 0
        puts theme.error.render("You must provide a name for the migration")
        return 1
      end
      if env["RACK_ENV"] != "development"
        puts theme.error.render("This only works in the development environment, not #{theme.code.render(env["RACK_ENV"])}")
        return 1
      end
      migrations_dir = Brut.container.migrations_dir
      name = argv.join(" ").gsub(/[^\w\d\-]/,"-")
      date = DateTime.now.strftime("%Y%m%d%H%M%S")
      file_name = migrations_dir / "#{date}_#{name}.rb"
      relative_path = file_name.relative_path_from(Brut.container.project_root)
      puts "Creating new migration file at #{theme.code.render(relative_path.to_s)}"
      info "Creating new migration file at #{file_name}"
      code = %{
Sequel.migration do
  up do
    # See https://brutrb.com/recipes/migrations.html
    # for a recipe on writing migrations
  end
end
}.strip
      if options.dry_run?
        puts theme.warning.render("Dry run - migration would contain this code:")
        puts theme.code.render(code)
      else
        File.open(file_name,"w") do |file|
          file.puts code
        end
        puts theme.success.render("✅ Migration created")
      end
      0
    end
  end

end
