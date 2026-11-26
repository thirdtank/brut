require "spec_helper"
require "nokogiri"

RSpec.describe Brut::FrontEnd::Components::I18nTranslations do
  let(:rack_env) { "test" }
  let(:project_env) { Brut::Framework::ProjectEnvironment.new(rack_env) }

  let(:translations) do
    {
      cv: {
        this_field: "This field",
        cs: {
          valueMissing: "%{field} is required",
          tooShort: "%{field} is too short",
        },
        ss: {
          taken: "%{field} is already taken",
        },
      },
    }
  end

  around do |example|
    original_backend   = I18n.backend
    original_load_path = I18n.load_path
    original_available = I18n.available_locales_initialized? ? I18n.available_locales : nil

    I18n.load_path = []
    I18n.backend = I18n::Backend::Simple.new
    I18n.backend.store_translations(:en, translations)
    I18n.available_locales = [:en]
    I18n.locale = :en

    example.run
  ensure
    I18n.available_locales = original_available
    I18n.load_path = original_load_path
    I18n.backend = original_backend
  end

  before do
    span = double(add_prefixed_attributes: nil)
    instrumentation = double
    allow(instrumentation).to receive(:span) { |_name, &block| block.call(span) }

    container = Brut::Framework::Container.new
    container.store("instrumentation", Object, "Instrumentation", instrumentation)
    container.store("project_env", Brut::Framework::ProjectEnvironment, "Project environment", project_env)
    allow(Brut).to receive(:container).and_return(container)
  end

  def render(root)
    Nokogiri::HTML5.fragment(described_class.new(root).call)
  end

  it "renders a blok-i18n-translation for a string root" do
    document = render("cv.this_field")
    translation = document.at_css("blok-i18n-translation")

    expect(translation).not_to eq(nil)
    expect(translation["key"]).to eq("cv.this_field")
    expect(translation["value"]).to eq("This field")
  end

  it "renders one blok-i18n-translation for each key under a namespace" do
    document = render("cv.cs")
    translations = document.css("blok-i18n-translation")

    expect(translations.map { |translation| translation["key"] }).to eq([
      "cv.cs.valueMissing",
      "cv.cs.tooShort",
    ])
    expect(translations.map { |translation| translation["value"] }).to eq([
      "%{field} is required",
      "%{field} is too short",
    ])
  end

  it "sets show-warnings and a blok-prefixed debug id outside production" do
    document = render("cv.cs")
    translation = document.at_css("blok-i18n-translation[key='cv.cs.valueMissing']")

    expect(translation).not_to eq(nil)
    expect(translation.key?("show-warnings")).to eq(true)
    expect(translation["id"]).to eq("blok-18n-valueMissing")
  end

  context "in production" do
    let(:rack_env) { "production" }

    it "does not set show-warnings or an id" do
      document = render("cv.cs")
      translation = document.at_css("blok-i18n-translation[key='cv.cs.valueMissing']")

      expect(translation).not_to eq(nil)
      expect(translation.key?("show-warnings")).to eq(false)
      expect(translation.key?("id")).to eq(false)
    end
  end

  it "raises when a value inside the root is not a String" do
    expect {
      described_class.new("cv").call
    }.to raise_error(RuntimeError, /maps to a Hash instead of a String/)
  end
end
