require "spec_helper"
require "rack/mock"
require "rack/request"

RSpec.describe Brut::FrontEnd::RouteHooks::LocaleDetection do
  class RecordingSession < Hash
    attr_reader :writes

    def initialize(*args)
      super
      @writes = []
    end

    def []=(key, value)
      @writes << [key, value]
      super
    end
  end

  before do
    instrumentation = double(add_attributes: nil, record_exception: nil)
    container = Brut::Framework::Container.new
    container.store("instrumentation", Object, "Instrumentation", instrumentation)
    allow(Brut).to receive(:container).and_return(container)

    @original_available_locales = ::I18n.available_locales.dup
    @original_default_locale = ::I18n.default_locale
    @original_locale = ::I18n.locale

    ::I18n.available_locales = [:en, :fr]
    ::I18n.default_locale = :en
  end

  after do
    ::I18n.available_locales = @original_available_locales
    ::I18n.default_locale = @original_default_locale
    ::I18n.locale = @original_locale
  end

  def hook_env(accept_language:, cookie:)
    headers = {}
    if !accept_language.nil?
      headers["HTTP_ACCEPT_LANGUAGE"] = accept_language
    end
    if !cookie.nil?
      headers["HTTP_COOKIE"] = cookie
    end
    Rack::MockRequest.env_for("/", headers)
  end

  def call_hook(session:, accept_language: nil, cookie: nil)
    env = hook_env(accept_language:, cookie:)
    described_class.new.before(session:, env:, request: Rack::Request.new(env))
  end

  def new_session
    recording_session = RecordingSession.new
    [Brut::FrontEnd::Session.new(rack_session: recording_session), recording_session]
  end

  def writes_for(recording_session, key)
    recording_session.writes.select { |(written_key, _)| written_key == key }
  end

  describe "the browser's time zone" do
    it "stores the cookie's time zone in the session" do
      session, recording_session = new_session

      call_hook(session:, cookie: "brut.timezone=America/New_York")

      expect(session.timezone.name).to eq("America/New_York")
      expect(recording_session.writes).to include(["__brut_timezone_from_browser", "America/New_York"])
    end

    it "stores a changed time zone" do
      session, recording_session = new_session
      call_hook(session:, cookie: "brut.timezone=America/New_York")
      recording_session.writes.clear

      call_hook(session:, cookie: "brut.timezone=Europe/Paris")

      expect(session.timezone.name).to             eq("Europe/Paris")
      expect(recording_session.writes).to     include(["__brut_timezone_from_browser", "Europe/Paris"])
      expect(recording_session.writes).not_to include(["__brut_timezone_from_browser", "America/New_York"])
    end

    it "keeps an explicit session time zone override" do
      session, = new_session
      session.timezone = "Europe/Paris"

      call_hook(session:, cookie: "brut.timezone=America/New_York")

      expect(session.timezone.name).to eq("Europe/Paris")
    end

    it "keeps the session's time zone when there is no cookie" do
      session, = new_session
      session.timezone_from_browser = "America/New_York"

      call_hook(session:)

      expect(session.timezone.name).to eq("America/New_York")
    end

    it "keeps the session's time zone when the cookie is invalid" do
      session, = new_session
      session.timezone_from_browser = "America/New_York"

      call_hook(session:, cookie: "brut.timezone=America/Nowhere")

      expect(session.timezone.name).to eq("America/New_York")
    end
  end

  describe "the Accept-Language header" do
    it "stores the header value in the session when the session has none" do
      session, recording_session = new_session

      call_hook(session:, accept_language: "fr")

      expect(session.http_accept_language.weighted_locales.map(&:locale)).to eq(["fr"])
      expect(writes_for(recording_session, "__brut_http_accept_language")).to eq([["__brut_http_accept_language", "fr;1"]])
    end

    it "replaces the session's existing value with the current header" do
      session, recording_session = new_session
      call_hook(session:, accept_language: "fr")
      recording_session.writes.clear

      call_hook(session:, accept_language: "en")

      expect(session.http_accept_language.weighted_locales.map(&:locale)).to eq(["en"])
      expect(writes_for(recording_session, "__brut_http_accept_language")).to eq([["__brut_http_accept_language", "en;1"]])
    end
  end
end
