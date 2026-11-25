require "spec_helper"

RSpec.describe Brut::FrontEnd::Download do
  describe "#headers" do
    it "exposes the download's data" do
      download = described_class.new(
        filename: "widget.txt",
        data: "widget data",
        content_type: "text/plain"
      )

      expect(download.data).to eq("widget data")
    end

    it "sets content-type" do
      download = described_class.new(
        filename: "widget.txt",
        data: "widget data",
        content_type: "text/plain"
      )

      expect(download.headers["content-type"]).to eq("text/plain")
    end

    it "sets a plain filename in a quoted string" do
      download = described_class.new(
        filename: "widget.txt",
        data: "widget data",
        content_type: "text/plain"
      )

      expect(download.headers["content-disposition"]).to eq(%(attachment; filename="widget.txt"))
    end

    it "prefixes the filename with an ISO-8601 timestamp when timestamp: is truthy" do
      allow(Time).to receive(:now).and_return(Time.utc(2030, 6, 15, 12, 34, 56))

      download = described_class.new(
        filename: "widget.txt",
        data: "widget data",
        content_type: "text/plain",
        timestamp: true
      )

      content_disposition = download.headers["content-disposition"]

      expect(content_disposition).to eq(%(attachment; filename="2030-06-15T12-34-56-widget.txt"))
    end
  end

  describe "invalid filenames" do
    it "raises when the filename contains a double quote" do
      expect {
        described_class.new(
          filename: %(a"b.txt),
          data: "widget data",
          content_type: "text/plain"
        ).headers
      }.to raise_error(ArgumentError, /filename/)
    end

    it "raises when the filename contains a single quote" do
      expect {
        described_class.new(
          filename: %(a'b.txt),
          data: "widget data",
          content_type: "text/plain"
        ).headers
      }.to raise_error(ArgumentError, /filename/)
    end

    it "raises when the filename contains a backslash" do
      expect {
        described_class.new(
          filename: "a\\b.txt",
          data: "widget data",
          content_type: "text/plain"
        ).headers
      }.to raise_error(ArgumentError, /filename/)
    end

    it "raises when the filename contains a carriage return" do
      expect {
        described_class.new(
          filename: "a\rb.txt",
          data: "widget data",
          content_type: "text/plain"
        ).headers
      }.to raise_error(ArgumentError, /filename/)
    end

    it "raises when the filename contains a newline" do
      expect {
        described_class.new(
          filename: "a\nb.txt",
          data: "widget data",
          content_type: "text/plain"
        ).headers
      }.to raise_error(ArgumentError, /filename/)
    end

    it "raises when the filename contains a tab" do
      expect {
        described_class.new(
          filename: "a\tb.txt",
          data: "widget data",
          content_type: "text/plain"
        ).headers
      }.to raise_error(ArgumentError, /filename/)
    end

    it "raises when the filename contains a NUL byte" do
      expect {
        described_class.new(
          filename: "a\u0000b.txt",
          data: "widget data",
          content_type: "text/plain"
        ).headers
      }.to raise_error(ArgumentError, /filename/)
    end
  end

  describe "non-ASCII filenames" do
    it "encodes them per RFC 5987 and keeps the header ASCII-only" do
      download = described_class.new(
        filename: "é.txt",
        data: "widget data",
        content_type: "text/plain"
      )

      content_disposition = download.headers["content-disposition"]

      expect(content_disposition.ascii_only?).to eq(true)
      expect(content_disposition).to include(%(filename*=UTF-8''%C3%A9.txt))
    end
  end
end
