require "spec_helper"
require "brut/tui"

RSpec.describe Brut::TUI::TerminalTheme do

  subject(:theme) { Brut::TUI::TerminalTheme.new }

  describe "#with_markup" do
    context "default text and reset" do
      it "parses the markup and resets at the end" do
        result = theme.with_markup("This is *bold* text")
        expect(result).to eq("\e[22mThis is \e[1mbold\e[22m text\e[0m")
        #                     ^^^^^^        ^^^^^    ^^^^^^     ^^^^^
        #                        |             |        |         |
        #                       normal       bold     bold off  reset at end
      end
    end
    context "error text and no reset" do
      it "parses the markup, sets all text to error, but no reset at the end" do
        result = theme.with_markup("This is *bold* text", text: :error, reset: false)
        expect(result).to eq("\e[1m\e[91mThis is \e[1mbold\e[22m\e[1m\e[91m text")
        #                     ^^^^^ ^^^^^        ^^^^^    ^^^^^^ ^^^^^^^^^^
        #                        |     |            |        |          |
        #                       bright |           bold     bold off    |
        #                             red                              bright red again
      end
    end
    context "unknown type of text" do
      it "parses the markup, treats text as normal, but no reset at the end" do
        result = theme.with_markup("This is *bold* text", text: :foobar, reset: false)
        expect(result).to eq("\e[22mThis is \e[1mbold\e[22m text")
        #                     ^^^^^^        ^^^^^    ^^^^^^
        #                        |             |        |
        #                       normal       bold     bold off
      end
    end
  end
end
