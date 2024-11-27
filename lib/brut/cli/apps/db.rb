require "sequel"
require "uri"
require "date"
require "brut/cli"

class Brut::CLI::Apps::DB < Brut::CLI::App
  description "Manage your database in development, test, and production"

  class Seed < Brut::CLI::Command
    description "Load seed data into the database"
    requires_project_env default: "development"

    def handle_bootstrap_exception(ex)
      case ex
      when Sequel::DatabaseConnectionError
        err.puts "Database needs to be created"
        stop_execution
      when Sequel::DatabaseError
        if ex.cause.kind_of?(PG::UndefinedTable)
          err.puts "Migrations need to be run"
          stop_execution
        else
          super
        end
      else
        super
      end
    end

    def execute
      seeds_dir = Brut.container.db_seeds_dir
      Dir["#{seeds_dir}/*.rb"].each do |file|
        require file
      end
      seed_data = Brut::Backend::SeedData.new
      seed_data.setup!
      seed_data.load_seeds!
      0
    rescue Sequel::UniqueConstraintViolation => ex
      out.puts "Seed data may have already been loaded: #{ex}"
    end
  end

  class Rebuild < Brut::CLI::Command
    description "Drop, re-create, and run migrations, effecitvely rebuilding the entire database"

    requires_project_env default: "development"

    def handle_bootstrap_exception(ex)
      case ex
      when Sequel::DatabaseConnectionError
        continue_execution
      when Sequel::DatabaseError
        if ex.cause.kind_of?(PG::UndefinedTable)
          continue_execution
        else
          super
        end
      else
        super
      end
    end

    def execute
      delegate_to_commands(Drop, Create, Migrate)
    end
  end

  class Create < Brut::CLI::Command
    description "Create the database if it does not exist"
    requires_project_env default: "development"

    def handle_bootstrap_exception(ex)
      case ex
      when Sequel::DatabaseConnectionError
        uri_no_database = URI(Brut.container.database_url.to_s)
        database_name = uri_no_database.path.gsub(/^\//,"")
        uri_no_database.path = ""
        begin
          connection = Sequel.connect(uri_no_database.to_s)
          out.puts "#{database_name} does not exit. Creating..."
          connection.run("CREATE DATABASE \"#{database_name}\"")
          connection.disconnect
        rescue => ex
          err.puts ex.message
        end
        stop_execution
      when Sequel::DatabaseError
        if ex.cause.kind_of?(PG::UndefinedTable)
          out.puts "Migrations need to be run"
          continue_execution
        else
          super
        end
      else
        super
      end
    end
    def execute
      connection = Sequel.connect(Brut.container.database_url)
      out.puts "Database already exists"
      connection.disconnect
      0
    rescue => ex
      handle_bootstrap_exception(ex)
    end
  end

  class Drop < Brut::CLI::Command
    description "Drop the database if it exists"
    requires_project_env default: "development"

    def handle_bootstrap_exception(ex)
      case ex
      when Sequel::DatabaseConnectionError
        out.puts "Database does not exist"
        stop_execution
      when Sequel::DatabaseError
        if ex.cause.kind_of?(PG::UndefinedTable)
          continue_execution
        else
          super
        end
      else
        super
      end
    end

    def execute
      uri_no_database = URI(Brut.container.database_url.to_s)
      database_name = uri_no_database.path.gsub(/^\//,"")
      uri_no_database.path = ""
      out.puts "Database exists. Dropping..."
      begin
        Brut.container.sequel_db_handle.disconnect
      rescue Sequel::DatabaseConnectionError
      end
      connection = Sequel.connect(uri_no_database.to_s)
      connection.run("DROP DATABASE IF EXISTS \"#{database_name}\"")
      connection.disconnect
      0
    rescue => ex
      handle_bootstrap_exception(ex)
    end
  end

  class Migrate < Brut::CLI::Command
    description "Apply any outstanding migrations to the database"
    requires_project_env default: "development"

    def handle_bootstrap_exception(ex)
      case ex
      when Sequel::DatabaseConnectionError
        err.puts "Database does not exist. Create it first"
        stop_execution
      when Sequel::DatabaseError
        if ex.cause.kind_of?(PG::UndefinedTable)
          # ignoring - we are running migrations which will address this
          continue_execution
        else
          super
        end
      else
        super
      end
    end

    def execute
      Sequel.extension :migration
      Brut.container.sequel_db_handle.extension :brut_migrations
      migrations_dir = Brut.container.migrations_dir
      if !migrations_dir.exist?
        err.puts "#{migrations_dir} doesn't exist"
        return
      end
      Brut.container.sequel_db_handle.extension :pg_array

      logger = Logger.new(STDOUT)
      logger.level = ENV["LOG_LEVEL"]
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
      out.puts "Migrations applied"
    end
  end

  class NewMigration < Brut::CLI::Command
    description "Create a new migration file"
    args "migration_name"

    def before_execute
      ENV["RACK_ENV"] = "development"
    end

    def execute
      if @args.length == 0
        return abort_execution("You must provide a name for the migration")
      end
      migrations_dir = Brut.container.migrations_dir
      name = @args.join(" ").gsub(/[^\w\d\-]/,"-")
      date = DateTime.now.strftime("%Y%m%d%H%M%S")
      file_name = migrations_dir / "#{date}_#{name}.rb"
      File.open(file_name,"w") do |file|
        file.puts "Sequel.migration do"
        file.puts "  up do"
        file.puts "  end"
        file.puts "end"
      end
      relative_path = file_name.relative_path_from(Brut.container.project_root)
      out.puts "Migration created:\n    #{relative_path}"
    end
  end

  class Status < Brut::CLI::Command
    description "Check the status of the database and migrations"
    requires_project_env default: "development"

    def handle_bootstrap_exception(ex)
      case ex
      when Sequel::DatabaseConnectionError
        uri_no_database = URI(Brut.container.database_url.to_s)
        database_name = uri_no_database.path.gsub(/^\//,"")
        uri_no_database.path = ""
        begin
          connection = Sequel.connect(uri_no_database.to_s)
          out.puts "Database Server is Up"
          out.puts "Database #{database_name} does not exist"
        rescue => ex
          err.puts ex.message
        end
        stop_execution
      when Sequel::DatabaseError
        if ex.cause.kind_of?(PG::UndefinedTable)
          err.puts "Migrations need to be run"
          continue_execution
        else
          super
        end
      end
    end

    def execute
      database_name = URI(Brut.container.database_url).path
      connection = Brut.container.sequel_db_handle
      out.puts "Database Server is Up"
      out.puts "Database #{database_name} exists"
      migrations_run = if connection.table_exists?("schema_migrations")
                         connection["select filename from schema_migrations order by filename"].all.map { |_| _[:filename] }
                       else
                         []
                       end
      migration_files = Dir[Brut.container.migrations_dir / "*.rb"].map { |file|
        filename = Pathname(file).basename.to_s
      }
      max_length = migration_files.map(&:length).max
      printf_string = "%-#{max_length}s - %s\n"
      migration_files.each do |filename|
        applied = migrations_run.include?(filename)
        printf(printf_string,filename,applied ? "✅ APPLIED" : "❌ NOT APPLIED")
      end
      0
    end
  end
end
