require "spec_helper"
require "brut/tui"

RSpec.describe Brut::TUI::MarkupString do
  describe ".from_string" do
    it "returns the same object if given a MarkupString" do
      markup_string = Brut::TUI::MarkupString.new("test")
      expect(Brut::TUI::MarkupString.from_string(markup_string)).to be(markup_string)
    end

    it "creates a new MarkupString if given a regular string" do
      str = "test"
      markup_string = Brut::TUI::MarkupString.from_string(str)
      expect(markup_string.class).to eq(Brut::TUI::MarkupString)
      expect(markup_string.to_s).to eq(str)
    end
  end

  describe "#parse" do
    it "yields text and markup events correctly" do
      markup_string = Brut::TUI::MarkupString.new("This is *bold* and _weak_ text, plus ~strike~ and `code`.")
      events = []
      markup_string.parse do |directive, value|
        events << [directive, value]
      end

      expected_events = [
        [:text, "T"], [:text, "h"], [:text, "i"], [:text, "s"], [:text, " "],
        [:text, "i"], [:text, "s"], [:text, " "],
        [:start, :bold], [:text, "b"], [:text, "o"], [:text, "l"], [:text, "d"], [:stop, :bold],
        [:text, " "], [:text, "a"], [:text, "n"], [:text, "d"], [:text, " "],
        [:start, :weak], [:text, "w"], [:text, "e"], [:text, "a"], [:text, "k"], [:stop, :weak],
        [:text, " "], [:text, "t"], [:text, "e"], [:text, "x"], [:text, "t"], [:text, ","], [:text, " "],
        [:text, "p"], [:text, "l"], [:text, "u"], [:text, "s"], [:text, " "],
        [:start, :strike], [:text, "s"], [:text, "t"], [:text, "r"], [:text, "i"], [:text, "k"], [:text, "e"], [:stop, :strike],
        [:text, " "], [:text, "a"], [:text, "n"], [:text, "d"], [:text, " "],
        [:start, :code], [:text, "c"], [:text, "o"], [:text, "d"], [:text, "e"], [:stop, :code],
        [:text, "."]
      ]
      expect(events).to eq(expected_events)
    end

    it "allows escaping of markup characters" do
      markup_string = Brut::TUI::MarkupString.new("This is \\*not bold\\* but this is *bold*.")
      events = []
      markup_string.parse do |directive, value|
        events << [directive, value]
      end

      expected_events = [
        [:text, "T"], [:text, "h"], [:text, "i"], [:text, "s"], [:text, " "],
        [:text, "i"], [:text, "s"], [:text, " "],
        [:text, "*"], [:text, "n"], [:text, "o"], [:text, "t"], [:text, " "],
        [:text, "b"], [:text, "o"], [:text, "l"], [:text, "d"], [:text, "*"],
        [:text, " "], [:text, "b"], [:text, "u"], [:text, "t"], [:text, " "],
        [:text, "t"], [:text, "h"], [:text, "i"], [:text, "s"], [:text, " "],
        [:text, "i"], [:text, "s"], [:text, " "],
        [:start, :bold], [:text, "b"], [:text, "o"], [:text, "l"], [:text, "d"], [:stop, :bold],
        [:text, "."]
      ]
      expect(events).to eq(expected_events)
    end

    it "allows backslashes to be escaped" do
      markup_string = Brut::TUI::MarkupString.new("Here is \\\\back")
      events = []
      markup_string.parse do |directive, value|
        events << [directive, value]
      end

      expected_events = [
        [:text, "H"], [:text, "e"], [:text, "r"], [:text, "e"], [:text, " "],
        [:text, "i"], [:text, "s"], [:text, " "],
        [:text, "\\"], [:text, "b"], [:text, "a"], [:text, "c"], [:text, "k"],
      ]
      expect(events).to eq(expected_events)
    end
  end
end
