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
    @original_locale = ::I18n.locale

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
    @sinatra_app_class.get("/__probe/timezone") do
      Brut.container.session_class.new(rack_session: session).timezone.name
    end
    @sinatra_app_class.get("/__probe/vary") do
      headers["Vary"] = "Cookie"
      "ok"
    end
    @sinatra_app_class.get("/__probe/vary-multiple") do
      headers["Vary"] = "Cookie, Accept-Encoding"
      "ok"
    end
    @sinatra_app_class.get("/__probe/vary-array") do
      headers["Vary"] = ["Cookie", "Accept-Encoding"]
      "ok"
    end
    @sinatra_app_class.get("/__probe/vary-star") do
      headers["Vary"] = "*"
      "ok"
    end
    @sinatra_app_class.get("/__probe/vary-lowercase") do
      headers["Vary"] = "accept-language, Cookie"
      "ok"
    end
    @sinatra_app_class.get("/__probe/vary-star-mixed") do
      headers["Vary"] = "Cookie, *"
      "ok"
    end
    @sinatra_app_class.get("/__probe/vary-array-comma") do
      headers["Vary"] = ["Cookie, Accept-Encoding"]
      "ok"
    end
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
    ::I18n.locale = @original_locale
    ENV["RACK_ENV"] = @original_rack_env
    ENV["DATABASE_URL"] = @original_database_url
    ENV["OTEL_TRACES_EXPORTER"] = @original_otel_traces_exporter
    FileUtils.remove_entry(@project_root)
  end

  let(:app) { @sinatra_app_class.new }

  def request(path, accept_language: nil, cookie: nil)
    env = {
      "rack.session" => {},
      "HTTP_ACCEPT_LANGUAGE" => accept_language,
    }
    if !cookie.nil?
      env["HTTP_COOKIE"] = cookie
    end
    Rack::MockRequest.new(app).get(path, env)
  end

  def normalized_vary_values(response)
    Array(response.headers["Vary"]).
      flat_map { |value| value.to_s.split(",") }.
      map(&:strip).
      map(&:downcase).
      reject(&:empty?).
      sort
  end

  def vary_tokens(response)
    Array(response.headers["Vary"]).flat_map { |value| value.to_s.split(",") }
  end

  it "provides a RequestContext during a request" do
    expect(request("/__probe/context").body).to eq("present")
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

  it "reads the browser's time zone from the brut.timezone cookie" do
    response = request("/__probe/timezone", cookie: "brut.timezone=America/New_York")

    confidence_check do
      expect(response.status).to eq(200)
    end
    expect(response.body).to eq("America/New_York")
  end

  it "ignores an invalid time zone cookie without failing the request" do
    response = request("/__probe/timezone", cookie: "brut.timezone=America/Nowhere")

    confidence_check do
      expect(response.status).to eq(200)
    end
    expect(response.body).to eq("UTC")
  end

  it "advertises the negotiated language in the response headers" do
    response = request("/__probe/locale", accept_language: "fr")

    confidence_check do
      expect(response.body).to eq("fr")
    end
    expect(response.headers["Content-Language"]).to eq("fr")
    expect(response.headers["Vary"].to_s.split(",").map(&:strip)).to include("accept-language")
  end

  it "advertises the default language when Accept-Language matches nothing" do
    response = request("/__probe/locale", accept_language: "zz")

    confidence_check do
      expect(response.body).to eq("en")
    end
    expect(response.headers["Content-Language"]).to eq("en")
  end

  it "uses the highest-weighted language that the app supports" do
    response = request("/__probe/locale", accept_language: "en;q=0.5, fr;q=0.9")

    confidence_check do
      expect(response.body).to eq("fr")
    end
    expect(response.headers["Content-Language"]).to eq("fr")
  end

  it "falls back to the primary language of a regional locale" do
    response = request("/__probe/locale", accept_language: "fr-CA")

    expect(response.body).to eq("fr")
  end

  it "uses the default language when the header is missing" do
    response = request("/__probe/locale")

    confidence_check do
      expect(response.body).to eq("en")
    end
    expect(response.headers["Content-Language"]).to eq("en")
  end

  it "uses the default language when the header is *" do
    response = request("/__probe/locale", accept_language: "*")

    expect(response.body).to eq("en")
  end

  it "ignores an Accept-Language tag that is not valid syntax" do
    response = request("/__probe/locale", accept_language: "fr_CA")

    expect(response.body).to eq("en")
  end

  it "ignores a wildcard that has a quality value" do
    response = request("/__probe/locale", accept_language: "*;q=0.9, en-US;q=0.5")

    expect(response.body).to eq("en")
  end

  it "ignores an invalid Accept-Language entry but uses the valid ones" do
    response = request("/__probe/locale", accept_language: "garbage();q=0.9, fr;q=0.5")

    expect(response.body).to eq("fr")
  end

  it "matches a language tag regardless of case" do
    response = request("/__probe/locale", accept_language: "FR")

    expect(response.body).to eq("fr")
  end

  it "merges Accept-Language into an existing Vary header" do
    response = request("/__probe/vary", accept_language: "fr")

    expect(normalized_vary_values(response)).to include("accept-language")
  end

  it "appends Accept-Language to a comma-separated Vary header without disturbing the existing values" do
    response = request("/__probe/vary-multiple", accept_language: "fr")

    expect(normalized_vary_values(response)).to eq(["accept-encoding", "accept-language", "cookie"])
  end

  it "appends Accept-Language to a Vary header given as an array" do
    response = request("/__probe/vary-array", accept_language: "fr")

    expect(normalized_vary_values(response)).to eq(["accept-encoding", "accept-language", "cookie"])
  end

  it "does not add Accept-Language to Vary: *" do
    response = request("/__probe/vary-star", accept_language: "fr")

    confidence_check do
      expect(response.status).to eq(200)
    end
    expect(normalized_vary_values(response)).to eq(["*"])
  end

  it "does not add a duplicate Accept-Language when one is already present in a different case" do
    response = request("/__probe/vary-lowercase", accept_language: "fr")

    accept_language_values = normalized_vary_values(response).select { |value| value.downcase == "accept-language" }
    expect(accept_language_values.size).to eq(1)
  end

  it "emits Vary tokens without surrounding whitespace" do
    response = request("/__probe/vary-multiple", accept_language: "fr")
    tokens = vary_tokens(response)

    expect(tokens.reject { |token| token == token.strip }).to eq([])
  end

  it "leaves Vary untouched when * appears alongside other tokens" do
    response = request("/__probe/vary-star-mixed", accept_language: "fr")

    expect(vary_tokens(response)).to eq(["*", "cookie"])
  end

  it "splits comma-separated values inside an array element" do
    response = request("/__probe/vary-array-comma", accept_language: "fr")
    tokens = vary_tokens(response)

    expect(tokens.length).to eq(3)
    expect(tokens).to include("cookie")
    expect(tokens).to include("accept-encoding")
    expect(tokens).to include("accept-language")
  end

  it "does not append a duplicate cookie token when Vary already names the cookie" do
    response = request("/__probe/vary", accept_language: "fr")
    tokens = vary_tokens(response)

    expect(tokens.map(&:downcase).select { |token| token == "cookie" }.size).to eq(1)
  end
end
