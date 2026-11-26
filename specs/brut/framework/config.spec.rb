require "spec_helper"
require "tmpdir"
require "pathname"
require "fileutils"

RSpec.describe Brut::Framework::Config do
  let(:container) { Brut::Framework::Container.new }
  let(:tmpdir)    { Dir.mktmpdir }

  before do
    container.store_required_path(
      "project_root",
      "Root of the entire project's source code checkout",
      Pathname(tmpdir),
    )
  end

  after do
    FileUtils.remove_entry(tmpdir)
  end

  def configure_for(rack_env)
    old_rack_env = ENV["RACK_ENV"]
    ENV["RACK_ENV"] = rack_env
    described_class.new(container:).configure!
  ensure
    ENV["RACK_ENV"] = old_rack_env
  end

  def with_permitted_hosts_env(value)
    old_value = ENV["PERMITTED_HOSTS"]
    ENV["PERMITTED_HOSTS"] = value
    yield
  ensure
    ENV["PERMITTED_HOSTS"] = old_value
  end

  def with_secure_cookies_env(value)
    old_value = ENV["SECURE_COOKIES"]
    ENV["SECURE_COOKIES"] = value
    yield
  ensure
    ENV["SECURE_COOKIES"] = old_value
  end

  def with_sequel_env(database_url:, max_connections:)
    old_database_url = ENV["DATABASE_URL"]
    old_max_connections = ENV["SEQUEL_MAX_CONNECTIONS"]
    ENV["DATABASE_URL"] = database_url
    ENV["SEQUEL_MAX_CONNECTIONS"] = max_connections
    yield
  ensure
    ENV["DATABASE_URL"] = old_database_url
    ENV["SEQUEL_MAX_CONNECTIONS"] = old_max_connections
  end

  describe "semantic_logger_appenders" do
    it "configures colorized stdout and a development log file in development" do
      configure_for("development")

      expect(container.semantic_logger_appenders).to eq([
        { formatter: :color, io: $stdout },
        { file_name: (container.log_dir / "development.log").to_s },
      ])
    end

    it "configures only a test log file in test" do
      configure_for("test")

      expect(container.semantic_logger_appenders).to eq(
        { file_name: (container.log_dir / "test.log").to_s }
      )
    end

    it "configures stdout only in production" do
      configure_for("production")

      expect(container.semantic_logger_appenders).to eq({ io: $stdout })
    end
  end

  describe "permitted_hosts" do
    it "permits local hosts, test domains, and all IPs in development" do
      configure_for("development")

      expect(container.permitted_hosts).to eq([
        "localhost",
        ".localhost",
        ".test",
        IPAddr.new("0.0.0.0/0"),
        IPAddr.new("::/0"),
      ])
    end

    it "permits local hosts, test domains, and all IPs in test" do
      configure_for("test")

      expect(container.permitted_hosts).to eq([
        "localhost",
        ".localhost",
        ".test",
        IPAddr.new("0.0.0.0/0"),
        IPAddr.new("::/0"),
      ])
    end

    it "uses production_permitted_hosts in production" do
      with_permitted_hosts_env("app.example.com, .example.com") do
        configure_for("production")

        expect(container.permitted_hosts).to eq(["app.example.com", ".example.com"])
      end
    end

    it "raises in production when production_permitted_hosts is not set" do
      with_permitted_hosts_env(nil) do
        configure_for("production")

        expect {
          container.permitted_hosts
        }.to raise_error(Brut::Framework::Errors::MissingConfiguration, /production_permitted_hosts/)
      end
    end

    it "raises in production when production_permitted_hosts is blank" do
      with_permitted_hosts_env(" ,     ,     ") do
        configure_for("production")

        expect {
          container.permitted_hosts
        }.to raise_error(Brut::Framework::Errors::MissingConfiguration, /production_permitted_hosts/)
      end
    end

    it "uses an overridden production_permitted_hosts in production" do
      with_permitted_hosts_env(nil) do
        configure_for("production")
        container.override("production_permitted_hosts", ["overridden.example.com"])

        expect(container.permitted_hosts).to eq(["overridden.example.com"])
      end
    end
  end

  describe "production_permitted_hosts" do
    it "defaults to the comma-separated value of PERMITTED_HOSTS" do
      with_permitted_hosts_env(" app.example.com, .example.com ,") do
        configure_for("production")

        expect(container.production_permitted_hosts).to eq(["app.example.com", ".example.com"])
      end
    end

    it "defaults to an empty array when PERMITTED_HOSTS is not set" do
      with_permitted_hosts_env(nil) do
        configure_for("production")

        expect(container.production_permitted_hosts).to eq([])
      end
    end
  end

  describe "secure_cookies?" do
    it "defaults to false in development" do
      with_secure_cookies_env(nil) do
        configure_for("development")

        expect(container.secure_cookies?).to eq(false)
      end
    end

    it "defaults to false in test" do
      with_secure_cookies_env(nil) do
        configure_for("test")

        expect(container.secure_cookies?).to eq(false)
      end
    end

    it "defaults to true in production" do
      with_secure_cookies_env(nil) do
        configure_for("production")

        expect(container.secure_cookies?).to eq(true)
      end
    end

    it "can be disabled in production via SECURE_COOKIES" do
      with_secure_cookies_env("false") do
        configure_for("production")

        expect(container.secure_cookies?).to eq(false)
      end
    end
  end

  describe "sequel_db_handle" do
    it "uses SEQUEL_MAX_CONNECTIONS for the connection pool size" do
      database_url = "postgres://example.test/widgets"
      with_sequel_env(database_url: database_url, max_connections: "17") do
        configure_for("test")
        allow(Sequel).to receive(:connect).and_return(double("Sequel database"))

        container.sequel_db_handle

        expect(Sequel).to have_received(:connect).with(
          database_url,
          max_connections: 17,
        )
      end
    end
    it "defaults to 5" do
      database_url = "postgres://example.test/widgets"
      with_sequel_env(database_url: database_url, max_connections: nil) do
        configure_for("test")
        allow(Sequel).to receive(:connect).and_return(double("Sequel database"))

        container.sequel_db_handle

        expect(Sequel).to have_received(:connect).with(
          database_url,
          max_connections: 5,
        )
      end
    end
  end
end
