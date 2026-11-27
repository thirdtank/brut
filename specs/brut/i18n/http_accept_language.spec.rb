require "spec_helper"

RSpec.describe Brut::I18n::HTTPAcceptLanguage do
  describe ".from_header" do
    it "parses a single locale with an assumed weight of 1" do
      parsed = described_class.from_header("fr")

      expect(parsed.weighted_locales.map(&:locale)).to eq(["fr"])
      expect(parsed.weighted_locales.map(&:q)).to eq([1])
    end

    it "orders locales from highest weight to lowest" do
      parsed = described_class.from_header("en;q=0.5, fr;q=0.9, de;q=0.1")

      expect(parsed.weighted_locales.map(&:locale)).to eq(["fr", "en", "de"])
    end

    it "treats a locale without q as weight 1" do
      parsed = described_class.from_header("fr, en;q=0.9")

      expect(parsed.weighted_locales.map(&:locale)).to eq(["fr", "en"])
      expect(parsed.weighted_locales.first.q).to eq(1)
    end

    it "keeps a region subtag intact and exposes its primary language" do
      parsed = described_class.from_header("fr-CA")
      weighted_locale = parsed.weighted_locales.first

      expect(weighted_locale.locale).to eq("fr-CA")
      expect(weighted_locale.primary_locale).to eq("fr")
    end

    it "canonicalizes the language to lowercase" do
      parsed = described_class.from_header("FR")

      expect(parsed.weighted_locales.map(&:locale)).to eq(["fr"])
    end

    it "canonicalizes the language to lowercase and the region to uppercase" do
      parsed = described_class.from_header("FR-ca")

      expect(parsed.weighted_locales.map(&:locale)).to eq(["fr-CA"])
    end

    it "returns AlwaysEnglish when the header is missing" do
      expect(described_class.from_header(nil)).to be_a(described_class::AlwaysEnglish)
    end

    it "returns AlwaysEnglish when the header is empty" do
      expect(described_class.from_header("")).to be_a(described_class::AlwaysEnglish)
    end

    it "returns AlwaysEnglish when the header is *" do
      expect(described_class.from_header("*")).to be_a(described_class::AlwaysEnglish)
    end
  end

  describe ".from_session" do
    it "round-trips a parsed header" do
      parsed = described_class.from_header("fr-CA, en;q=0.5")
      round_tripped = described_class.from_session(parsed.for_session)

      expect(round_tripped.weighted_locales.map(&:locale)).to eq(["fr-CA", "en"])
      expect(round_tripped.weighted_locales.map(&:q)).to eq(["1", "0.5"])
    end

    it "returns AlwaysEnglish when the session value is blank" do
      expect(described_class.from_session(nil)).to be_a(described_class::AlwaysEnglish)
      expect(described_class.from_session("")).to be_a(described_class::AlwaysEnglish)
    end
  end
end
