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
      stdout.puts "Database server is up"
      stdout.puts "Database #{database_name} exists"
      migrations_run = if connection.table_exists?("schema_migrations")
                         connection["select filename from schema_migrations order by filename"].all.map { |_| _[:filename] }
                       else
                         []
                       end
      migration_files = Dir[Brut.container.migrations_dir / "*.rb"].map { |file|
        filename = Pathname(file).basename.to_s
      }
      if migration_files.empty? && migrations_run.empty?
        stdout.puts("✅ NO MIGRATION FILES TO RUN")
      else
        max_length = migration_files.map(&:length).max
        printf_string = "%-#{max_length}s - %s\n"
        migration_files.each do |filename|
          applied = migrations_run.include?(filename)
          stdout.printf(printf_string,filename,applied ? "✅ APPLIED" : "❌ NOT APPLIED")
        end
      end
      0
    rescue Sequel::DatabaseConnectionError => ex
      uri_no_database = URI(Brut.container.database_url.to_s)
      database_name = uri_no_database.path.gsub(/^\//,"")
      uri_no_database.path = ""
      begin
        connection = Sequel.connect(uri_no_database.to_s)
        stdout.puts "Database server is up"
        stdout.puts "Database #{database_name} does not exist - run `brut db create` to create it"
        0
      rescue => ex2
        stderr.puts "Database server is not running at #{uri_no_database}: #{ex2.message}"
        stderr.puts "This could be a problem with your dev environment generally, or your .env.test or .env.test.local files"
        1
      end
    end
  end

  class Create < Brut::CLI::Commands::BaseCommand
    def description = "Create the database if it does not exist"
    def default_rack_env = "development"
    def bootstrap? = false

    def run
      connection = Sequel.connect(Brut.container.database_url)
      stdout.puts "Database already exists"
      connection.disconnect
      0
    rescue Sequel::DatabaseConnectionError => ex
      uri_no_database = URI(Brut.container.database_url.to_s)
      database_name = uri_no_database.path.gsub(/^\//,"")
      uri_no_database.path = ""
      begin
        connection = Sequel.connect(uri_no_database.to_s)
        stdout.puts "Database #{database_name} does not exist. Creating..."
        connection.run("CREATE DATABASE \"#{database_name}\"")
        connection.disconnect
        0
      rescue Sequel::DatabaseConnectionError => ex2
        stderr.puts "Database server is not running at #{uri_no_database}: #{ex2.message}"
        stderr.puts "This could be a problem with your dev environment generally, or your .env.test or .env.test.local files"
        1
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
        stdout.puts "Database #{database_name} exists. Dropping..."
        connection = Sequel.connect(uri_no_database.to_s)
        connection.run("DROP DATABASE IF EXISTS \"#{database_name}\"")
        connection.disconnect
        0
      rescue Sequel::DatabaseConnectionError => ex
        begin
          connection = Sequel.connect(uri_no_database.to_s)
          stdout.puts "Database #{database_name} does not exist"
          connection.disconnect
          0
        rescue Sequel::DatabaseConnectionError => ex2
          stderr.puts "Database server is not running at #{uri_no_database}: #{ex2.message}"
          stderr.puts "This could be a problem with your dev environment generally, or your .env.test or .env.test.local files"
          1
        end
      end
    end
  end

  class Migrate < Brut::CLI::Commands::BaseCommand
    def description = "Apply any outstanding migrations to the database"
    def default_rack_env = "development"

    def run
      migrations_dir = Brut.container.migrations_dir
      if !migrations_dir.exist?
        stdout.puts "No migrations to run from #{migrations_dir}"
        return 0
      elsif Dir[migrations_dir / "*.rb"].empty?
        stdout.puts "No migrations to run from #{migrations_dir}"
        return 0
      end

      Sequel.extension :migration
      Brut.container.sequel_db_handle.extension :brut_migrations
      Brut.container.sequel_db_handle.extension :pg_array

      logger = Logger.new(STDOUT)
      logger.level = self.options.log_level
      indent = ""
      logger.formatter = proc { |severity,time,progname,message|
        formatted = "#{indent} - #{message}\n"
        if message =~ /^Begin applying/
          indent = "   "
        elsif message =~ /^Finished applying/
          indent = ""
          formatted = "#{indent} - #{message}\n"
        end
        formatted
      }
      Brut.container.sequel_db_handle.logger = logger
      Sequel::Migrator.run(Brut.container.sequel_db_handle,migrations_dir)
      stdout.puts "All migrations have been applied"
      0
    rescue Sequel::DatabaseConnectionError => ex
      stderr.puts "Database #{Brut.container.database_url} does not exist. Create it first with `brut db create`"
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
      Dir["#{seeds_dir}/*.rb"].each do |file|
        require file
      end
      seed_data = Brut::BackEnd::SeedData.new
      seed_data.setup!
      seed_data.load_seeds!
      0
    rescue Sequel::DatabaseConnectionError => ex
      stderr.puts "Database doesn't exist. Create it with `brut db create`"
      1
    rescue Sequel::UniqueConstraintViolation => ex
      stderr.puts "Seed data may have already been loaded: #{ex}. You can re-load it using `brut db rebuild`, then `brut db seed`"
      1
    rescue Sequel::DatabaseError => ex
      if ex.cause.kind_of?(PG::UndefinedTable)
        stderr.puts "Migrations need to be run. Use `brut db migrate` to run them"
        1
      else
        raise ex
      end
    end
  end

  class NewMigration < Brut::CLI::Commands::BaseCommand
    def description = "Create a new migration file"
    def args_description = "migration_name"
    def bootstrap? = false

    def before_execute
      ENV["RACK_ENV"] = "development"
    end

    def run
      if argv.length == 0
        stderr.puts "You must provide a name for the migration"
        return 1
      end
      if env["RACK_ENV"] != "development"
        stderr.puts "This only works in the development environment, not #{env["RACK_ENV"]}"
        return 1
      end
      migrations_dir = Brut.container.migrations_dir
      name = argv.join(" ").gsub(/[^\w\d\-]/,"-")
      date = DateTime.now.strftime("%Y%m%d%H%M%S")
      file_name = migrations_dir / "#{date}_#{name}.rb"
      File.open(file_name,"w") do |file|
        file.puts "Sequel.migration do"
        file.puts "  up do"
        file.puts "    # See https://brutrb.com/recipes/migrations.html"
        file.puts "    # for a recipe on writing migrations"
        file.puts "  end"
        file.puts "end"
      end
      relative_path = file_name.relative_path_from(Brut.container.project_root)
      stdout.puts "Migration created:\n    #{relative_path}"
      0
    end
  end

end
