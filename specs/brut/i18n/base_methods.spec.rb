require "spec_helper"
require "cgi"
require "date"
require "phlex"

RSpec.describe Brut::I18n::BaseMethods do
  # A real object satisfying the three-method protocol that BaseMethods
  # assumes: `safe`, `capture`, and `html_escape`.
  class TestTranslator
    include Brut::I18n::BaseMethods

    def safe(string)
      Phlex::SGML::SafeValue.new(string)
    end

    def capture(&block)
      block.call
    end

    def html_escape(value)
      CGI.escapeHTML(value)
    end
  end

  class BaseMethodsTestComponent < Brut::FrontEnd::Component
  end

  class BaseMethodsTestPage < Brut::FrontEnd::Page
    class WidgetComponent < Brut::FrontEnd::Component
    end
  end

  around do |example|
    original_backend   = I18n.backend
    original_load_path = I18n.load_path

    I18n.load_path = []
    I18n.backend = I18n::Backend::Simple.new
    I18n.backend.store_translations(:en, {
      cv: {
        this_field: "this field",
      },
      hello: "Hi!",
      actions: {
        edit: "Make an edit",
      },
      greeting: "Hello %{name}!",
      required: "%{field} is required",
      with_block: "Before %{block} after",
      things: {
        zero: "No things",
        one: "One thing",
        other: "%{count} things",
      },
      namespace: {
        nested: "Nested value",
      },
      date: {
        formats: {
          default: "%Y-%m-%d",
        },
      },
      components: {
        "BaseMethodsTestComponent" => {
          greeting: "Component greeting %{name}!",
        },
        "BaseMethodsTestPage::WidgetComponent" => {
          greeting: "Widget greeting %{name}!",
        },
      },
      pages: {
        "BaseMethodsTestPage" => {
          greeting: "Page greeting %{name}!",
          nevermind: "Page nevermind",
        },
      },
    })

    example.run
  ensure
    I18n.load_path = original_load_path
    I18n.backend = original_backend
  end

  describe "#t" do
    it "finds a translation by Symbol or String key" do
      translator = TestTranslator.new

      expect(translator.t(:hello)).to eq("Hi!")
      expect(translator.t("hello")).to eq("Hi!")
    end

    it "turns an Array key into a dotted key" do
      translator = TestTranslator.new

      expect(translator.t([:actions, :edit])).to eq("Make an edit")
    end

    it "escapes interpolated String values" do
      translator = TestTranslator.new

      expect(translator.t(:greeting, name: "<b>Pat</b>")).to eq("Hello &lt;b&gt;Pat&lt;/b&gt;!")
    end

    it "escapes interpolated Symbol values" do
      translator = TestTranslator.new

      result = translator.t(:greeting, name: :"<script>alert(1)</script>")

      expect(result).to eq("Hello &lt;script&gt;alert(1)&lt;/script&gt;!")
    end

    it "escapes interpolated values based on their to_s" do
      translator = TestTranslator.new
      injected = Struct.new(:html) do
        def to_s = html
      end.new("<script>alert(1)</script>")

      result = translator.t(:greeting, name: injected)

      expect(result).to eq("Hello &lt;script&gt;alert(1)&lt;/script&gt;!")
    end

    it "uses cv.this_field when a translation interpolates field but none was given" do
      translator = TestTranslator.new

      expect(translator.t(:required)).to eq("this field is required")
    end

    it "uses the given field value when one was given" do
      translator = TestTranslator.new

      expect(translator.t(:required, field: "Email")).to eq("Email is required")
    end

    it "uses the block's contents for a %{block} interpolation" do
      translator = TestTranslator.new

      result = translator.t(:with_block) { "click here" }

      expect(result).to eq("Before click here after")
    end

    it "does not escape block contents, which are marked safe" do
      translator = TestTranslator.new

      result = translator.t(:with_block) { "<b>click here</b>" }

      expect(result).to eq("Before <b>click here</b> after")
    end

    it "does not escape interpolated values that are already marked safe" do
      translator = TestTranslator.new
      safe_value = Phlex::SGML::SafeValue.new("<b>Pat</b>")

      result = translator.t(:greeting, name: safe_value)

      expect(result).to eq("Hello <b>Pat</b>!")
    end

    it "escapes a block: interpolation value" do
      translator = TestTranslator.new

      result = translator.t(:with_block, block: "<b>click here</b>")

      expect(result).to eq("Before &lt;b&gt;click here&lt;/b&gt; after")
    end

    it "raises when given both a block and a block: value" do
      translator = TestTranslator.new

      expect {
        translator.t(:with_block, block: "click here") { "other" }
      }.to raise_error(ArgumentError, /block: param/)
    end

    it "raises when a %{block} translation is used without a block" do
      translator = TestTranslator.new

      expect {
        translator.t(:with_block)
      }.to raise_error(ArgumentError, /%\{block\}/)
    end

    it "keeps count numeric when choosing a pluralization" do
      translator = TestTranslator.new

      expect(translator.t(:things, count: 0)).to eq("No things")
      expect(translator.t(:things, count: 1)).to eq("One thing")
      expect(translator.t(:things, count: 2)).to eq("2 things")
    end

    it "raises when a pluralized translation is used without count" do
      translator = TestTranslator.new

      expect {
        translator.t(:things)
      }.to raise_error(I18n::MissingInterpolationArgument, /count/)
    end

    it "raises a Bug error when the key points to a namespace rather than a translation" do
      translator = TestTranslator.new

      expect {
        translator.t(:namespace)
      }.to raise_error(Brut::Framework::Errors::Bug, /namespace/)
    end

    it "raises when no translation is found" do
      translator = TestTranslator.new

      expect {
        translator.t(:does_not_exist)
      }.to raise_error(I18n::MissingTranslationData)
    end
  end

  describe "#t in a Component" do
    it "prefers a component-specific translation and falls back to the literal key" do
      component = BaseMethodsTestComponent.new

      expect(component.t(:greeting, name: "Pat").to_s).to eq("Component greeting Pat!")
      expect(component.t(:hello).to_s).to eq("Hi!")
    end
  end

  describe "#t in a Page" do
    it "prefers a page-specific translation and falls back to the literal key" do
      page = BaseMethodsTestPage.new

      expect(page.t(:greeting, name: "Pat").to_s).to eq("Page greeting Pat!")
      expect(page.t(:hello).to_s).to eq("Hi!")
    end
  end

  describe "#t in a page-private Component" do
    it "checks the component, then the page, then the literal key" do
      component = BaseMethodsTestPage::WidgetComponent.new

      expect(component.t(:greeting, name: "Pat").to_s).to eq("Widget greeting Pat!")
      expect(component.t(:nevermind).to_s).to eq("Page nevermind")
      expect(component.t(:hello).to_s).to eq("Hi!")
    end
  end

  describe "#t_direct" do
    it "uses the first key that exists" do
      translator = TestTranslator.new

      expect(translator.t_direct([:does_not_exist, :hello])).to eq("Hi!")
    end

    it "raises when none of the keys exist" do
      translator = TestTranslator.new

      expect {
        translator.t_direct([:does_not_exist, :also_missing])
      }.to raise_error(I18n::MissingTranslationData)
    end

    it "uses key_given to identify the key in a Bug error" do
      translator = TestTranslator.new

      expect {
        translator.t_direct(:namespace, key_given: "my.key")
      }.to raise_error(Brut::Framework::Errors::Bug, /Key 'my.key'/)
    end
  end

  describe "#l" do
    it "localizes using I18n" do
      translator = TestTranslator.new

      expect(translator.l(Date.new(2030, 6, 15))).to eq("2030-06-15")
    end
  end
end
