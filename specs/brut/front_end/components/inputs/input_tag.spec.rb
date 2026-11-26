require "spec_helper"
require "nokogiri"

RSpec.describe Brut::FrontEnd::Components::Inputs::InputTag do

  before do
    span = double(add_prefixed_attributes: nil)
    instrumentation = double
    allow(instrumentation).to receive(:span) { |_name, &block| block.call(span) }

    container = Brut::Framework::Container.new
    container.store("instrumentation", Object, "Instrumentation", instrumentation)
    allow(Brut).to receive(:container).and_return(container)
  end

  def input_from(html) = Nokogiri::HTML5(html).at_css("input")

  describe "generating HTML" do
    it "generates the input's type, name, required, and value, omitting constraints that are not set" do
      form_class = Class.new(Brut::FrontEnd::Form) { input :name }
      form = form_class.new(params: { name: "Dave" })

      input = input_from(described_class.new(form:, input_name: :name).call)

      expect(input["type"]).to           eq("text")
      expect(input["name"]).to           eq("name")
      expect(input["value"]).to          eq("Dave")
      expect(input.key?("required")).to  eq(true)
      expect(input.key?("pattern")).to   eq(false)
      expect(input.key?("min")).to       eq(false)
      expect(input.key?("max")).to       eq(false)
      expect(input.key?("minlength")).to eq(false)
      expect(input.key?("maxlength")).to eq(false)
      expect(input.key?("step")).to      eq(false)
    end

    it "omits the value attribute when the input has no value" do
      form_class = Class.new(Brut::FrontEnd::Form) { input :name }
      form = form_class.new(params: {})

      input = input_from(described_class.new(form:, input_name: :name).call)

      expect(input.key?("value")).to eq(false)
    end

    it "generates non-String values as Strings" do
      form_class = Class.new(Brut::FrontEnd::Form) { input :name }
      form = form_class.new(params: { name: 10 })

      input = input_from(described_class.new(form:, input_name: :name).call)

      expect(input["value"]).to eq("10")
    end

    it "generates every constraint attribute that is defined on the input" do
      form_class = Class.new(Brut::FrontEnd::Form) {
        input :code, minlength: 2, maxlength: 5, min: 1, max: 10, step: 2, pattern: "[a-z]+"
      }
      form = form_class.new(params: {})

      input = input_from(described_class.new(form:, input_name: :code).call)

      expect(input["pattern"]).to   eq("[a-z]+")
      expect(input["minlength"]).to eq("2")
      expect(input["maxlength"]).to eq("5")
      expect(input["min"]).to       eq("1")
      expect(input["max"]).to       eq("10")
      expect(input["step"]).to      eq("2")
    end

    it "merges extra HTML attributes last, allowing them to override generated ones" do
      form_class = Class.new(Brut::FrontEnd::Form) { input :name }
      form = form_class.new(params: { name: "Dave" })

      input = input_from(
        described_class.new(
          form:,
          input_name: :name,
          class: "big",
          value: "override",
          **{ "data-testid" => "name-input" }
        ).call
      )

      expect(input["class"]).to       eq("big")
      expect(input["value"]).to       eq("override")
      expect(input["data-testid"]).to eq("name-input")
    end
  end

  describe "checkboxes" do
    it "generates value='true', no checked, and no required when unchecked" do
      form_class = Class.new(Brut::FrontEnd::Form) { input :terms, type: "checkbox" }
      form = form_class.new(params: {})

      input = input_from(described_class.new(form:, input_name: :terms).call)

      expect(input["type"]).to          eq("checkbox")
      expect(input["name"]).to          eq("terms")
      expect(input["value"]).to         eq("true")
      expect(input.key?("checked")).to  eq(false)
      expect(input.key?("required")).to eq(false)
    end

    it "generates checked when the input's value is 'true'" do
      form_class = Class.new(Brut::FrontEnd::Form) { input :terms, type: "checkbox" }
      form = form_class.new(params: { terms: true })

      input = input_from(described_class.new(form:, input_name: :terms).call)

      expect(input["value"]).to        eq("true")
      expect(input.key?("checked")).to eq(true)
    end

    it "uses the index as the value for array checkboxes and checks the inputs that were submitted as true" do
      form_class = Class.new(Brut::FrontEnd::Form) { input :tags, type: "checkbox", array: true }
      form = form_class.new(params: { tags: [true, false] })

      first  = input_from(described_class.new(form:, input_name: :tags, index: 0).call)
      second = input_from(described_class.new(form:, input_name: :tags, index: 1).call)

      expect(first["name"]).to          eq("tags[]")
      expect(first["value"]).to         eq("0")
      expect(first.key?("checked")).to  eq(true)

      expect(second["name"]).to         eq("tags[]")
      expect(second["value"]).to        eq("1")
      expect(second.key?("checked")).to eq(false)
    end

    it "generates value='true' for a non-array checkbox even when index 0 is given" do
      form_class = Class.new(Brut::FrontEnd::Form) { input :terms, type: "checkbox" }
      form = form_class.new(params: { terms: true })

      input = input_from(described_class.new(form:, input_name: :terms, index: 0).call)

      expect(input["value"]).to        eq("true")
      expect(input.key?("checked")).to eq(true)
    end
  end

  describe "array inputs" do
    it "uses the [] suffix in the name and generates the value at the given index" do
      form_class = Class.new(Brut::FrontEnd::Form) { input :name, array: true }
      form = form_class.new(params: { name: ["Alice", "Bob"] })

      first  = input_from(described_class.new(form:, input_name: :name, index: 0).call)
      second = input_from(described_class.new(form:, input_name: :name, index: 1).call)

      expect(first["name"]).to  eq("name[]")
      expect(first["value"]).to eq("Alice")

      expect(second["name"]).to  eq("name[]")
      expect(second["value"]).to eq("Bob")
    end

    it "generates an empty input for an index with no submitted value" do
      form_class = Class.new(Brut::FrontEnd::Form) { input :name, array: true }
      form = form_class.new(params: { name: ["Alice"] })

      first  = input_from(described_class.new(form:, input_name: :name, index: 0).call)
      second = input_from(described_class.new(form:, input_name: :name, index: 1).call)

      expect(first["name"]).to  eq("name[]")
      expect(first["value"]).to eq("Alice")

      expect(second["name"]).to       eq("name[]")
      expect(second.key?("value")).to eq(false)
    end
  end

  describe "invalid usage" do
    it "raises when used with an input that is not a plain input, such as a select" do
      form_class = Class.new(Brut::FrontEnd::Form) { select :color }
      form = form_class.new(params: {})

      expect {
        described_class.new(form:, input_name: :color).call
      }.to raise_error(Brut::FrontEnd::Components::Inputs::InvalidInputClassForFormInput)
    end

    it "raises when a non-array input is given a non-zero index, but allows index 0" do
      form_class = Class.new(Brut::FrontEnd::Form) { input :name }
      form = form_class.new(params: { name: "Dave" })

      expect {
        described_class.new(form:, input_name: :name, index: 1).call
      }.to raise_error(ArgumentError, /index/)

      input = input_from(described_class.new(form:, input_name: :name, index: 0).call)
      expect(input["name"]).to eq("name")
      expect(input["value"]).to eq("Dave")
    end

    it "raises when an array input is not given an index" do
      form_class = Class.new(Brut::FrontEnd::Form) { input :name, array: true }
      form = form_class.new(params: { name: ["Alice", "Bob"] })

      expect {
        described_class.new(form:, input_name: :name).call
      }.to raise_error(ArgumentError, /index/)

      input = input_from(described_class.new(form:, input_name: :name, index: 0).call)
      expect(input["name"]).to eq("name[]")
      expect(input["value"]).to eq("Alice")
    end
  end
end
