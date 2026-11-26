require "spec_helper"
require "rack/mock"
require "tmpdir"

RSpec.describe "request lifecycle" do
  before do
    @original_rack_env = ENV["RACK_ENV"]
    @original_database_url = ENV["DATABASE_URL"]
    @original_otel_traces_exporter = ENV["OTEL_TRACES_EXPORTER"]
    @original_load_path = ::I18n.load_path.dup
    @original_available_locales = ::I18n.available_locales.dup

    @project_root = Pathname(Dir.mktmpdir("brut-request-lifecycle"))
    (@project_root / "app" / "config" / "i18n" / "en").mkpath
    (@project_root / "app" / "config" / "i18n" / "fr").mkpath

    ENV["RACK_ENV"] = "test"
    ENV["DATABASE_URL"] = "mock://"
    ENV["OTEL_TRACES_EXPORTER"] = "none"

    allow(Kernel).to receive(:at_exit)

    container = Brut::Framework::Container.new
    allow(Brut).to receive(:container).and_return(container)
    container.store_required_path(
      "project_root",
      "Root of the project used to probe the request lifecycle",
      @project_root,
    )

    app_klass = Class.new(Brut::Framework::App) do
      def id = "request-lifecycle-test"
    end

    mcp = Brut::Framework::MCP.new(app_klass:)
    mcp.define_singleton_method(:boot_postgres!) { nil }
    mcp.boot!

    @sinatra_app_class = mcp.sinatra_app
    # Sinatra's environment is fixed when sinatra/base is first required, which
    # depends on which test file loaded it. Pin it so a raised exception
    # propagates instead of being rendered by ShowExceptions.
    @sinatra_app_class.set :environment, :test
    @sinatra_app_class.get("/__probe/context") { Brut::FrontEnd::RequestContext.current.nil? ? "nil" : "present" }
    @sinatra_app_class.get("/__probe/locale") { ::I18n.locale.to_s }
    @sinatra_app_class.get("/__probe/raise") do
      if Brut::FrontEnd::RequestContext.current.nil?
        raise "RequestContext was not set before the route ran"
      end
      raise "boom"
    end
  end

  after do
    ::I18n.load_path = @original_load_path
    ::I18n.available_locales = @original_available_locales
    ENV["RACK_ENV"] = @original_rack_env
    ENV["DATABASE_URL"] = @original_database_url
    ENV["OTEL_TRACES_EXPORTER"] = @original_otel_traces_exporter
    FileUtils.remove_entry(@project_root)
  end

  let(:app) { @sinatra_app_class.new }

  def request(path, accept_language: nil)
    Rack::MockRequest.new(app).get(
      path,
      {
        "rack.session" => {},
        "HTTP_ACCEPT_LANGUAGE" => accept_language,
      },
    )
  end

  it "provides a RequestContext during a request" do
    confidence_check do
      expect(request("/__probe/context").body).to eq("present")
    end
  end

  it "removes the RequestContext from the thread once the request is done" do
    request("/__probe/context")

    expect(Brut::FrontEnd::RequestContext.current).to be_nil
  end

  it "removes the RequestContext from the thread when request processing raises" do
    expect { request("/__probe/raise") }.to raise_error("boom")

    expect(Brut::FrontEnd::RequestContext.current).to be_nil
  end

  it "does not leak one visitor's locale into the next visitor's request" do
    first_request = request("/__probe/locale", accept_language: "fr")
    second_request = request("/__probe/locale", accept_language: "zz")

    confidence_check do
      expect(first_request.body).to eq("fr")
    end
    expect(second_request.body).to eq("en")
  end
end
