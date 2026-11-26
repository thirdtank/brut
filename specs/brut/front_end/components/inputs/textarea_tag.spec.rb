require "spec_helper"
require "nokogiri"

RSpec.describe Brut::FrontEnd::Components::Inputs::TextareaTag do

  before do
    span = double(add_prefixed_attributes: nil)
    instrumentation = double
    allow(instrumentation).to receive(:span) { |_name, &block| block.call(span) }

    container = Brut::Framework::Container.new
    container.store("instrumentation", Object, "Instrumentation", instrumentation)
    allow(Brut).to receive(:container).and_return(container)
  end

  def textarea_from(html) = Nokogiri::HTML5(html).at_css("textarea")

  describe "generating HTML" do
    it "generates the name, required, and the value as text content, omitting constraints that are not set" do
      form_class = Class.new(Brut::FrontEnd::Form) { input :bio }
      form = form_class.new(params: { bio: "Hello" })

      textarea = textarea_from(described_class.new(form:, input_name: :bio).call)

      expect(textarea["name"]).to          eq("bio")
      expect(textarea.key?("required")).to eq(true)
      expect(textarea.text).to             eq("Hello")
      expect(textarea.key?("maxlength")).to eq(false)
      expect(textarea.key?("minlength")).to eq(false)
    end

    it "generates no content when the input has no value" do
      form_class = Class.new(Brut::FrontEnd::Form) { input :bio }
      form = form_class.new(params: {})

      textarea = textarea_from(described_class.new(form:, input_name: :bio).call)

      expect(textarea.text).to eq("")
    end

    it "generates non-String values as Strings" do
      form_class = Class.new(Brut::FrontEnd::Form) { input :bio }
      form = form_class.new(params: { bio: 10 })

      textarea = textarea_from(described_class.new(form:, input_name: :bio).call)

      expect(textarea.text).to eq("10")
    end

    it "generates maxlength and minlength when they are defined on the input" do
      form_class = Class.new(Brut::FrontEnd::Form) {
        input :bio, minlength: 2, maxlength: 200
      }
      form = form_class.new(params: { bio: "Hello" })

      textarea = textarea_from(described_class.new(form:, input_name: :bio).call)

      expect(textarea["maxlength"]).to eq("200")
      expect(textarea["minlength"]).to eq("2")
    end

    it "merges extra HTML attributes last, allowing them to override some of the generated ones" do
      form_class = Class.new(Brut::FrontEnd::Form) { input :bio }
      form = form_class.new(params: { bio: "Hello" })

      textarea = textarea_from(
        described_class.new(
          form:,
          input_name: :bio,
          name: "override-not-allowed",
          rows: 5,
          cols: 40,
          class: "big"
        ).call
      )

      expect(textarea["rows"]).to  eq("5")
      expect(textarea["cols"]).to  eq("40")
      expect(textarea["class"]).to eq("big")
      expect(textarea.text).to     eq("Hello")
    end
  end

  describe "array inputs" do
    it "uses the [] suffix in the name and generates the value at the given index" do
      form_class = Class.new(Brut::FrontEnd::Form) { input :bio, array: true }
      form = form_class.new(params: { bio: ["one", "two"] })

      first  = textarea_from(described_class.new(form:, input_name: :bio, index: 0).call)
      second = textarea_from(described_class.new(form:, input_name: :bio, index: 1).call)

      expect(first["name"]).to  eq("bio[]")
      expect(first.text).to     eq("one")

      expect(second["name"]).to eq("bio[]")
      expect(second.text).to    eq("two")
    end

    it "generates an empty textarea for an index with no submitted value" do
      form_class = Class.new(Brut::FrontEnd::Form) { input :bio, array: true }
      form = form_class.new(params: { bio: ["one"] })

      first  = textarea_from(described_class.new(form:, input_name: :bio, index: 0).call)
      second = textarea_from(described_class.new(form:, input_name: :bio, index: 1).call)

      expect(first["name"]).to eq("bio[]")
      expect(first.text).to    eq("one")

      expect(second["name"]).to eq("bio[]")
      expect(second.text).to    eq("")
    end
  end

  describe "invalid usage" do
    it "raises when used with an input that is not a plain input, such as a select" do
      form_class = Class.new(Brut::FrontEnd::Form) { select :color }
      form = form_class.new(params: { color: "red" })

      expect {
        described_class.new(form:, input_name: :color).call
      }.to raise_error(Brut::FrontEnd::Components::Inputs::InvalidInputClassForFormInput)
    end

    it "raises when a non-array input is given a non-zero index, but allows index 0" do
      form_class = Class.new(Brut::FrontEnd::Form) { input :bio }
      form = form_class.new(params: { bio: "Hello" })

      expect {
        described_class.new(form:, input_name: :bio, index: 1).call
      }.to raise_error(ArgumentError, /index/)

      textarea = textarea_from(described_class.new(form:, input_name: :bio, index: 0).call)
      expect(textarea["name"]).to eq("bio")
      expect(textarea.text).to    eq("Hello")
    end

    it "raises when an array input is not given an index" do
      form_class = Class.new(Brut::FrontEnd::Form) { input :bio, array: true }
      form = form_class.new(params: { bio: ["one", "two"] })

      expect {
        described_class.new(form:, input_name: :bio).call
      }.to raise_error(ArgumentError, /index/)

      textarea = textarea_from(described_class.new(form:, input_name: :bio, index: 0).call)
      expect(textarea["name"]).to eq("bio[]")
      expect(textarea.text).to    eq("one")
    end
  end
end
