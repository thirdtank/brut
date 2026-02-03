require "spec_helper"
require "tmpdir"
require "pathname"
require "fileutils"
require "brut/cli"
require "brut/back_end/seed_data"
require "pg"

RSpec.describe Brut::CLI::Apps::DB do
  let(:test_container)         { Brut::Framework::Container.new }
  let(:database_server_url)    { "postgres://1.2.3.4" }
  let(:database_name)          { "testing" }

  before do
    allow(Brut).to receive(:container).and_return(test_container)
    Brut.container.store("database_url", String, "", "#{database_server_url}/#{database_name}")
  end

  describe described_class::Status, cli_command: true do
    let(:tmpdir) { Dir.mktmpdir }

    before do
      Brut.container.store("migrations_dir", Pathname, "", Pathname(tmpdir) / "migrations")
      FileUtils.mkdir_p(Brut.container.migrations_dir)
    end

    after do
      FileUtils.remove_entry(tmpdir)
    end

    context "database can be connected-to" do
      let(:sequel_database_handle) { double("Sequel database handle") }
      before do
        Brut.container.store("sequel_db_handle", Object, "", sequel_database_handle)
      end
      context "schema_migrations table exists" do
        context "migrations have all been run" do
          it "indicates all is well" do
            stdout = StringIO.new
            File.open(Brut.container.migrations_dir / "1-foo.rb", "w") { it.puts "# doesn't matter" }
            File.open(Brut.container.migrations_dir / "2-bar.rb", "w") { it.puts "# doesn't matter" }
            allow(sequel_database_handle).to receive(:table_exists?).with("schema_migrations").and_return(true)
            sequel_dataset = double("Sequel Dataset", all: [
              { filename: "1-foo.rb" },
              { filename: "2-bar.rb" },
            ])
            allow(sequel_database_handle).to receive(:[]).and_return(sequel_dataset)

            result = described_class.new.execute(test_execution_context(stdout:))
            expect(result).to eq(0)
            expect(stdout.string).not_to include("NOT APPLIED")
            expect(stdout.string).to match(/1-foo.*APPLIED/)
            expect(stdout.string).to match(/2-bar.*APPLIED/)
          end
        end
        context "some migrations have not been run" do
          it "indicates which files have not been run" do
            stdout = StringIO.new
            File.open(Brut.container.migrations_dir / "1-foo.rb", "w") { it.puts "# doesn't matter" }
            File.open(Brut.container.migrations_dir / "2-bar.rb", "w") { it.puts "# doesn't matter" }
            allow(sequel_database_handle).to receive(:table_exists?).with("schema_migrations").and_return(true)
            sequel_dataset = double("Sequel Dataset", all: [
              { filename: "1-foo.rb" },
            ])
            allow(sequel_database_handle).to receive(:[]).and_return(sequel_dataset)

            result = described_class.new.execute(test_execution_context(stdout:))
            expect(result).to eq(0)
            expect(stdout.string).to match(/1-foo.*APPLIED/)
            expect(stdout.string).not_to match(/1-foo.*NOT APPLIED/)
            expect(stdout.string).to match(/2-bar.*NOT APPLIED/)
          end
        end
      end
      context "schema_migrations table does not exist" do
        context "there are migration files" do
          it "indicates that all existing files must be run" do
            stdout = StringIO.new
            File.open(Brut.container.migrations_dir / "1-foo.rb", "w") { it.puts "# doesn't matter" }
            File.open(Brut.container.migrations_dir / "2-bar.rb", "w") { it.puts "# doesn't matter" }
            allow(sequel_database_handle).to receive(:table_exists?).with("schema_migrations").and_return(false)

            result = described_class.new.execute(test_execution_context(stdout:))
            expect(result).to eq(0)
            expect(stdout.string).to match(/1-foo.*NOT APPLIED/)
            expect(stdout.string).to match(/2-bar.*NOT APPLIED/)
          end
        end
        context "there are not migration files" do
          it "indicates that all is well" do
            stdout = StringIO.new
            allow(sequel_database_handle).to receive(:table_exists?).with("schema_migrations").and_return(false)

            result = described_class.new.execute(test_execution_context(stdout:))
            expect(result).to eq(0)
            expect(stdout.string).to match(/NO MIGRATION FILES/)
          end
        end
      end
    end
    context "database cannot be connected-to" do
      context "server is up" do
        it "warns that the database doesn't exist and how to create it" do
          Brut.container.store("sequel_db_handle", Object, "") do
            raise Sequel::DatabaseConnectionError
          end
          stdout = StringIO.new
          allow(Sequel).to receive(:connect).with(database_server_url)
          result = described_class.new.execute(test_execution_context(stdout:))
          expect(result).to eq(0)
          expect(stdout.string).to match(/Database Server.*UP/)
          expect(stdout.string).to match(/Database testing.*DOES NOT EXIST/)
        end
      end
      context "server is not up" do
        it "warns that the database server isn't running" do
          Brut.container.store("sequel_db_handle", Object, "") do
            raise Sequel::DatabaseConnectionError
          end
          stdout = StringIO.new
          allow(Sequel).to receive(:connect).and_raise(Sequel::DatabaseConnectionError)
          result = described_class.new.execute(test_execution_context(stdout:))
          expect(result).to eq(1)
          expect(stdout.string).to match(/Database server is not running at #{database_server_url}/)
        end
      end
    end
  end

  describe described_class::Create, cli_command: true do

    context "database can be connected-to" do
      it "indicates all is well" do
        connection = double("Sequel database connection")
        allow(Sequel).to receive(:connect).with(Brut.container.database_url).and_return(connection)
        allow(connection).to receive(:disconnect)
        stdout = StringIO.new
        result = described_class.new.execute(test_execution_context(stdout:))
        expect(result).to eq(0)
        expect(stdout.string).to match(/Database testing already exists/)
        expect(connection).to have_received(:disconnect)
      end
    end

    context "database cannot be connected-to" do
      context "server is up" do
        it "creates the database" do
          allow(Sequel).to receive(:connect).with(Brut.container.database_url).and_raise(Sequel::DatabaseConnectionError)
          connection = double("Sequel database connection")
          allow(Sequel).to receive(:connect).with(database_server_url).and_return(connection)
          allow(connection).to receive(:run)
          allow(connection).to receive(:disconnect)
          stdout = StringIO.new
          result = described_class.new.execute(test_execution_context(stdout:))
          expect(result).to eq(0)
          expect(stdout.string).to match(/Database testing does not exist.*Creating/)
          expect(connection).to have_received(:run).with("CREATE DATABASE \"testing\"")
          expect(connection).to have_received(:disconnect)
        end
      end
      context "server is not up" do
        it "warns that the database server isn't running" do
          allow(Sequel).to receive(:connect).with(Brut.container.database_url).and_raise(Sequel::DatabaseConnectionError)
          allow(Sequel).to receive(:connect).with(database_server_url).and_raise(Sequel::DatabaseConnectionError)
          stdout = StringIO.new
          result = described_class.new.execute(test_execution_context(stdout:))
          expect(result).to eq(1)
          expect(stdout.string).to match(/Database server is not running at #{database_server_url}/)
        end
      end
    end
  end

  describe described_class::Drop, cli_command: true do

    context "database can be connected-to" do
      it "drops the database" do
        sequel_database_handle = double("Sequel database handle")
        Brut.container.store("sequel_db_handle", Object, "", sequel_database_handle)

        connection = double("Sequel database connection")

        allow(Sequel).to receive(:connect).with(database_server_url).and_return(connection)
        allow(connection).to receive(:run)
        allow(connection).to receive(:disconnect)
        allow(sequel_database_handle).to receive(:disconnect)

        stdout = StringIO.new
        result = described_class.new.execute(test_execution_context(stdout:))
        expect(result).to eq(0)
        expect(stdout.string).to match(/Database testing exists.*Dropping.../)
        expect(connection).to have_received(:run).with("DROP DATABASE IF EXISTS \"testing\"")
        expect(connection).to have_received(:disconnect)
        expect(sequel_database_handle).to have_received(:disconnect)
      end
    end

    context "database cannot be connected-to" do
      context "server is up" do
        it "reports that all is well" do
          Brut.container.store("sequel_db_handle", Object, "") do 
            raise Sequel::DatabaseConnectionError
          end

          connection = double("Sequel database connection")

          allow(Sequel).to receive(:connect).with(database_server_url).and_return(connection)
          allow(connection).to receive(:disconnect)

          stdout = StringIO.new
          result = described_class.new.execute(test_execution_context(stdout:))
          expect(result).to eq(0)
          expect(stdout.string).to match(/Database testing has already been dropped/)
        end
      end
      context "server is not up" do
        it "reports the error" do
          Brut.container.store("sequel_db_handle", Object, "") do 
            raise Sequel::DatabaseConnectionError
          end

          allow(Sequel).to receive(:connect).with(database_server_url).and_raise(Sequel::DatabaseConnectionError)

          stdout = StringIO.new
          result = described_class.new.execute(test_execution_context(stdout:))
          expect(result).to eq(1)
          expect(stdout.string).to match(/Database server is not running at #{database_server_url}/)
        end
      end
    end
  end
  describe described_class::Migrate, cli_command: true do
    let(:tmpdir) { Dir.mktmpdir }

    before do
      Brut.container.store("migrations_dir", Pathname, "", Pathname(tmpdir) / "migrations")
    end

    after do
      FileUtils.remove_entry(tmpdir)
    end
    context "database can be connected-to" do
      context "migrations dir does not exist" do
        it "says all is well and does nothing" do
          stdout = StringIO.new
          result = described_class.new.execute(test_execution_context(stdout:))
          expect(result).to eq(0)
          expect(stdout.string).to match(/No migrations to run/)
        end
      end
      context "migrations dir exists" do
        before do
          FileUtils.mkdir_p(Brut.container.migrations_dir)
        end
        context "there are no migrations files" do
          it "says all is well and does nothing" do
            stdout = StringIO.new
            result = described_class.new.execute(test_execution_context(stdout:))
            expect(result).to eq(0)
            expect(stdout.string).to match(/No migrations to run/)
          end
        end
        context "there are migrations files" do
          it "uses Sequel's migrator to run migrations" do
            sequel_database_handle = double("Sequel database handle")
            Brut.container.store("sequel_db_handle", Object, "", sequel_database_handle)
            Sequel.extension :migration
            allow(sequel_database_handle).to receive(:extension)
            allow(sequel_database_handle).to receive(:logger=)
            allow(Sequel::Migrator).to receive(:run)

            File.open(Brut.container.migrations_dir / "1-foo.rb", "w") { it.puts "# doesn't matter" }
            File.open(Brut.container.migrations_dir / "2-bar.rb", "w") { it.puts "# doesn't matter" }

            stdout = StringIO.new
            result = described_class.new.execute(test_execution_context(stdout:))

            expect(result).to eq(0)
            expect(stdout.string).to match(/All migrations have been applied/)

            expect(Sequel::Migrator).to have_received(:run).with(Brut.container.sequel_db_handle,
                                                                 Brut.container.migrations_dir)
            expect(sequel_database_handle).to have_received(:extension).with(:brut_migrations)
            expect(sequel_database_handle).to have_received(:extension).with(:pg_array)
          end
        end
        context "database cannot be connected-to" do
          it "warns that the database must be created first" do
            sequel_database_handle = double("Sequel database handle")
            Brut.container.store("sequel_db_handle", Object, "") do
              raise Sequel::DatabaseConnectionError
            end

            File.open(Brut.container.migrations_dir / "1-foo.rb", "w") { it.puts "# doesn't matter" }
            File.open(Brut.container.migrations_dir / "2-bar.rb", "w") { it.puts "# doesn't matter" }

            stdout = StringIO.new
            result = described_class.new.execute(test_execution_context(stdout:))
            expect(result).to eq(1)
            expect(stdout.string).to match(/Database.*testing does not exist/)
            expect(stdout.string).to match(/brut db create/)
          end
        end
      end
    end
  end
  describe described_class::Seed, cli_command: true do
    let(:tmpdir) { Dir.mktmpdir }

    before do
      Brut.container.store("db_seeds_dir",Pathname,"",Pathname(tmpdir) / "seeds")
      Brut.container.store("project_root",Pathname,"",Pathname(tmpdir) / "project_root")
      FileUtils.mkdir_p(Brut.container.db_seeds_dir)
      File.open(Brut.container.db_seeds_dir / "1_test_seed.rb", "w") do |file|
        file.puts "class TestSeedData1; end"
      end
      File.open(Brut.container.db_seeds_dir / "2_test_seed.rb", "w") do |file|
        file.puts "class TestSeedData2; end"
      end
    end

    after do
      FileUtils.remove_entry(tmpdir)
    end

    context "database exists" do
      context "migrations have been run" do
        context "seed data doesn't appear to have been loaded" do
          it "requires all seeds and loads the seed data" do
            seed_data = instance_double(Brut::BackEnd::SeedData)
            allow(Brut::BackEnd::SeedData).to receive(:new).and_return(seed_data)
            allow(seed_data).to receive(:setup!)
            allow(seed_data).to receive(:load_seeds!)

            result = described_class.new.execute(test_execution_context)
            expect(result).to eq(0)
            expect(!!defined?(TestSeedData1)).to eq(true)
            expect(!!defined?(TestSeedData2)).to eq(true)
          end
        end
        context "seed data may have been loaded" do
          it "warns that seed data may have already been loaded" do
            seed_data = instance_double(Brut::BackEnd::SeedData)
            allow(Brut::BackEnd::SeedData).to receive(:new).and_return(seed_data)
            allow(seed_data).to receive(:setup!)
            allow(seed_data).to receive(:load_seeds!).and_raise(Sequel::UniqueConstraintViolation)

            stdout = StringIO.new

            result = described_class.new.execute(test_execution_context(stdout:))
            expect(result).to eq(1)
            expect(stdout.string).to match(/Seed data may have already been loaded/)
            expect(stdout.string).to match(/brut db rebuild/)
          end
        end
      end
    end
  end
  describe described_class::NewMigration, cli_command: true do
    let(:tmpdir) { Dir.mktmpdir }

    before do
      Brut.container.store("project_root",Pathname,"",Pathname(tmpdir) / "project_root")
      Brut.container.store("migrations_dir",Pathname,"",Pathname(tmpdir) / "project_root" / "migrations")
      FileUtils.mkdir_p(Brut.container.migrations_dir)
      FileUtils.mkdir_p(Brut.container.project_root)
    end

    after do
      FileUtils.remove_entry(tmpdir)
    end
    context "argv not empty" do
      context "RACK_ENV is development" do
        it "creates a new migration file" do
          stdout = StringIO.new
          result = described_class.new.execute(test_execution_context(stdout:,
                                                                      env: { "RACK_ENV" => "development" },
                                                                      argv: [ "some", "new", "migration" ]))

          date = DateTime.now.strftime("%Y%m%d%H%M%S")
          base_file_name = "#{date}_some-new-migration.rb"
          file_name = Brut.container.migrations_dir / base_file_name

          expect(result).to eq(0)
          expect(File.exist?(file_name)).to eq(true)
          expect(stdout.string).to match(/#{base_file_name}/)
        end
      end
      context "RACK_ENV is not development" do
        it "warns that this may not be used outside development" do
          stdout = StringIO.new
          result = described_class.new.execute(test_execution_context(stdout:,
                                                                      env: { "RACK_ENV" => "test" },
                                                                      argv: [ "some", "new", "migration" ]))


          expect(result).to eq(1)
          expect(stdout.string).to match(/only works in the development/)
        end
      end
    end
    context "argv empty" do
      it "warns that a name is required" do
        stdout = StringIO.new
        result = described_class.new.execute(test_execution_context(stdout:,
                                                                    env: { "RACK_ENV" => "test" },
                                                                    argv: []))


        expect(result).to eq(1)
        expect(stdout.string).to match(/You must provide a name/)
      end
    end
  end
end
