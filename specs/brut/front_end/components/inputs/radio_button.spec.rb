require "spec_helper"
require "nokogiri"

RSpec.describe Brut::FrontEnd::Components::Inputs::RadioButton do

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
    it "generates a radio input with the group's name, the given value, and required, omitting checked when the form's value does not match" do
      form_class = Class.new(Brut::FrontEnd::Form) { radio_button_group :size }
      form = form_class.new(params: { size: "large" })

      input = input_from(described_class.new(form:, input_name: :size, value: "small").call)

      expect(input["type"]).to          eq("radio")
      expect(input["name"]).to          eq("size")
      expect(input["value"]).to         eq("small")
      expect(input.key?("required")).to eq(true)
      expect(input.key?("checked")).to  eq(false)
    end

    it "generates checked when the form's value matches the radio's value" do
      form_class = Class.new(Brut::FrontEnd::Form) { radio_button_group :size }
      form = form_class.new(params: { size: "small" })

      input = input_from(described_class.new(form:, input_name: :size, value: "small").call)

      expect(input["value"]).to        eq("small")
      expect(input.key?("checked")).to eq(true)
    end

    it "omits required when the radio button group is not required" do
      form_class = Class.new(Brut::FrontEnd::Form) { radio_button_group :size, required: false }
      form = form_class.new(params: { size: "small" })

      input = input_from(described_class.new(form:, input_name: :size, value: "small").call)

      expect(input.key?("required")).to eq(false)
      expect(input.key?("checked")).to  eq(true)
    end

    it "merges extra HTML attributes last, allowing them to override generated ones" do
      form_class = Class.new(Brut::FrontEnd::Form) { radio_button_group :size }
      form = form_class.new(params: { size: "small" })

      input = input_from(
        described_class.new(
          form:,
          input_name: :size,
          value: "small",
          html_attributes: {
            class: "big",
            value: "override",
            "data-testid" => "size-radio",
          }
        ).call
      )

      expect(input["class"]).to       eq("big")
      expect(input["value"]).to       eq("override")
      expect(input["data-testid"]).to eq("size-radio")
    end
  end

  describe "matching values" do
    it "checks the radio button when the form's value is a String and the radio's value is the same number" do
      form_class = Class.new(Brut::FrontEnd::Form) { radio_button_group :size }
      form = form_class.new(params: { size: 1 })

      input = input_from(described_class.new(form:, input_name: :size, value: 1).call)

      expect(input["value"]).to        eq("1")
      expect(input.key?("checked")).to eq(true)
    end

    it "omits the value attribute and is not checked when the value is nil" do
      form_class = Class.new(Brut::FrontEnd::Form) { radio_button_group :size }
      form = form_class.new(params: {})

      input = input_from(described_class.new(form:, input_name: :size, value: nil).call)

      expect(input.key?("value")).to   eq(false)
      expect(input.key?("checked")).to eq(false)
    end
  end

  describe "invalid usage" do
    it "raises when used with an input that is not a radio button group, such as a plain radio input" do
      form_class = Class.new(Brut::FrontEnd::Form) { input :size, type: "radio" }
      form = form_class.new(params: { size: "small" })

      expect {
        described_class.new(form:, input_name: :size, value: "small").call
      }.to raise_error(Brut::FrontEnd::Components::Inputs::InvalidInputClassForFormInput)
    end
  end
end
