require "spec_helper"
require "brut/tui"

RSpec.describe Brut::TUI::AnsiEscapeCode do
  describe "#to_s" do
    it "returns the ANSI escape code as a string" do
      code = Brut::TUI::AnsiEscapeCode.new(:red, "31")
      expect(code.to_s).to eq("\e[31m")
    end
  end

  describe ".ansi" do
    it "returns the correct ANSI escape code for a given name" do
      red_code = Brut::TUI::AnsiEscapeCode.ansi(:red)
      expect(red_code.to_s).to eq("\e[31m")
    end

    it "returns an RGB ANSI escape code when given RGB values" do
      rgb_code = Brut::TUI::AnsiEscapeCode.ansi(255, 0, 0)
      expect(rgb_code.to_s).to eq("\e[38;2;255;0;0m")
    end

    it "returns a fluent objects when called without arguments" do
      fluent = Brut::TUI::AnsiEscapeCode.ansi
      expect(fluent.bold.to_s).to eq("\e[1m")
      expect(fluent.red.to_s).to eq("\e[31m")
    end

  end
end
