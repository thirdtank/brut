require "spec_helper"

RSpec.describe "RichString" do
  describe ".from_string" do
    context "nil" do
      it "returns nil when blank_is_nil is true" do
        expect(RichString.from_string(nil)).to eq(nil)
      end
      it "returns nil when blank_is_nil is false" do
        expect(RichString.from_string(nil, blank_is_nil: false)).to eq(nil)
      end
    end
    context "empty string" do
      it "returns nil when blank_is_nil is true" do
        expect(RichString.from_string("     ")).to eq(nil)
      end
      it "returns the string when blank_is_nil is false" do
        expect(RichString.from_string("     ", blank_is_nil: false)).to eq("     ")
      end
    end
    context "non-empty string" do
      it "returns a RichString containing the string" do
        rich_string = RichString.from_string(" foo    ")
        expect(rich_string.to_str).to eq(" foo    ")
      end
    end
  end
  describe "#underscorized" do
    it "returns self if there's nothing to convert" do
      rich_string = RichString.new("alreadydone")
      expect(rich_string.underscorized).to eq(rich_string)
    end
    it "splits up CamelCase, turns - into _ and downcases everything" do
      rich_string = RichString.new("DashBoardPage")
      expect(rich_string.underscorized.to_s).to eq("dash_board_page")
    end
    it "handles weird situations" do
      rich_string = RichString.new("Dash--BoardHTMLPage---")
      expect(rich_string.underscorized.to_s).to eq("dash_board_h_t_m_l_page")
    end
    it "handles namespaces" do
      rich_string = RichString.new("WebHooks::Stripe")
      expect(rich_string.underscorized.to_s).to eq("web_hooks/stripe")
    end
  end
  describe "#camelize" do
    it "splits on _ and -, captializes each part and joins them" do
      expect(RichString.new("a-normal-base-case").camelize).to eq("ANormalBaseCase")
      expect(RichString.new("an__odd-_-----_one").camelize).to eq("AnOddOne")
      expect(RichString.new("Somewhat-Close").camelize).to eq("SomewhatClose")
      expect(RichString.new("AlreadyDone").camelize).to eq("AlreadyDone")
    end
  end
  describe "#capitalize" do
    context "first_only" do
      it "capitalizes the first letter, but does not affect the case of remaining letters" do
        expect(RichString.new("this is a String").capitalize(:first_only).to_s).to eq("This is a String")
      end
    end
    context "no first_only" do
      it "behaves as Ruby's stdlib does, which is to capitalize the first letter and downcase the rest" do
        expect(RichString.new("this is a String").capitalize.to_s).to eq("This is a string")
      end
    end
  end
  describe "#humanized" do
    it "replaces - and _ with spaces" do
      expect(RichString.new("this-is-a-string").humanized).to eq("this is a string")
    end
  end
  describe "#to_s_or_nil" do
    it "returns nil if the string is empty" do
      expect(RichString.new("   ").to_s_or_nil).to eq(nil)
    end
    it "returns the string if the string is not empty" do
      expect(RichString.new(" foo ").to_s_or_nil).to eq(" foo ")
    end
  end
end
