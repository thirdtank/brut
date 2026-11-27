require "spec_helper"

RSpec.describe Brut::FrontEnd::Session do
  before do
    @instrumentation = double(record_exception: nil)
    container = Brut::Framework::Container.new
    container.store("instrumentation", Object, "Instrumentation", @instrumentation)
    container.store("flash_class", Class, "Flash class", Brut::FrontEnd::Flash)
    allow(Brut).to receive(:container).and_return(container)

    @original_tz = ENV["TZ"]
    ENV.delete("TZ")
  end

  after do
    ENV["TZ"] = @original_tz
  end

  subject(:session) { described_class.new(rack_session: {}) }

  describe "#http_accept_language" do
    it "defaults to AlwaysEnglish when nothing is stored" do

      expect(session.http_accept_language).to be_a(Brut::I18n::HTTPAcceptLanguage::AlwaysEnglish)
      expect(session.http_accept_language.for_session).to eq("en;1")
    end

    it "returns the value that was assigned" do
      session.http_accept_language = Brut::I18n::HTTPAcceptLanguage.from_header("fr;q=0.5")

      expect(session.http_accept_language.weighted_locales.map(&:locale)).to eq(["fr"])
      expect(session.http_accept_language.weighted_locales.map(&:q)).to eq(["0.5"])
    end

    it "replaces a previously stored value" do
      session.http_accept_language = Brut::I18n::HTTPAcceptLanguage.from_header("fr")
      session.http_accept_language = Brut::I18n::HTTPAcceptLanguage.from_header("en")

      expect(session.http_accept_language.weighted_locales.map(&:locale)).to eq(["en"])
    end

    it "replaces a previously stored value when assigned AlwaysEnglish" do
      session.http_accept_language = Brut::I18n::HTTPAcceptLanguage.from_header("fr")
      session.http_accept_language = Brut::I18n::HTTPAcceptLanguage.from_session(nil)

      expect(session.http_accept_language.weighted_locales.map(&:locale)).to eq(["en"])
    end
  end

  describe "#timezone_from_browser" do
    it "returns nil when nothing is stored" do
      expect(session.timezone_from_browser).to eq(nil)
    end

    it "returns the time zone that was assigned as a string" do
      session.timezone_from_browser = "America/New_York"

      expect(session.timezone_from_browser.name).to eq("America/New_York")
    end

    it "returns the time zone that was assigned as a TZInfo::Timezone" do
      session.timezone_from_browser = TZInfo::Timezone.get("Europe/Paris")

      expect(session.timezone_from_browser.name).to eq("Europe/Paris")
    end

    it "does not store an invalid time zone's name" do
      rack_session = {}
      session = described_class.new(rack_session:)
      session.timezone_from_browser = "America/Nowhere"

      expect(rack_session["__brut_timezone_from_browser"]).to eq(nil)
    end

    it "keeps a previously stored time zone when assigned an invalid one" do
      session.timezone_from_browser = "America/New_York"
      session.timezone_from_browser = "America/Nowhere"

      expect(session.timezone_from_browser.name).to eq("America/New_York")
    end

    it "returns nil and records an exception when the stored value is invalid" do
      session[:__brut_timezone_from_browser] = "America/Nowhere"

      expect(session.timezone_from_browser).to eq(nil)
      expect(@instrumentation).to have_received(:record_exception)
    end
  end

  describe "#timezone" do
    it "prefers the explicit override" do
      session.timezone_from_browser = "America/New_York"
      session.timezone = "Europe/Paris"

      expect(session.timezone.name).to eq("Europe/Paris")
    end

    it "falls back to the browser's time zone when the override is cleared" do
      session.timezone_from_browser = "America/New_York"
      session.timezone = "Europe/Paris"
      session.timezone = nil

      expect(session.timezone.name).to eq("America/New_York")
    end

    it "accepts the override as a TZInfo::Timezone" do
      session.timezone = TZInfo::Timezone.get("Europe/Paris")

      expect(session.timezone.name).to eq("Europe/Paris")
    end

    it "prefers the browser's time zone over ENV[\"TZ\"]" do
      ENV["TZ"] = "Asia/Tokyo"
      session.timezone_from_browser = "America/New_York"

      expect(session.timezone.name).to eq("America/New_York")
    end

    it "uses ENV[\"TZ\"] when nothing else is available" do
      ENV["TZ"] = "Asia/Tokyo"

      expect(session.timezone.name).to eq("Asia/Tokyo")
    end

    it "falls back to UTC when nothing else is available" do
      expect(session.timezone.name).to eq("UTC")
    end

    it "falls back to the browser's time zone when the override is invalid" do
      session.timezone_from_browser = "America/New_York"
      session.timezone = "America/Nowhere"

      expect(session.timezone.name).to eq("America/New_York")
      expect(@instrumentation).to have_received(:record_exception)
    end

    it "falls back to UTC when ENV[\"TZ\"] is invalid" do
      ENV["TZ"] = "America/Nowhere"

      expect(session.timezone.name).to eq("UTC")
      expect(@instrumentation).to have_received(:record_exception)
    end
  end

  describe "hash access" do
    it "coerces keys to strings" do
      session[:widget_id] = "42"

      expect(session["widget_id"]).to eq("42")
      expect(session[:widget_id]).to eq("42")
    end

    it "deletes a value" do
      session[:widget_id] = "42"
      session.delete(:widget_id)

      expect(session[:widget_id]).to eq(nil)
    end
  end

  describe "flash" do
    it "returns an empty flash when nothing is stored" do
      expect(session.flash.to_h).to eq(Brut::FrontEnd::Flash.new.to_h)
    end

    it "returns the flash that was assigned" do
      session.flash = Brut::FrontEnd::Flash.new(age: 1, messages: { notice: "example.notice" })

      expect(session.flash.to_h).to eq(age: 1, messages: { notice: "example.notice" })
    end
  end
end
