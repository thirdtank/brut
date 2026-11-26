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

  describe "constraint validation attributes" do
    it "does not mark a new form's required radio button as invalid" do
      form_class = Class.new(Brut::FrontEnd::Form) { radio_button_group :size }
      form = form_class.new

      input = input_from(described_class.new(form:, input_name: :size, value: "small").call)

      expect(input.key?("aria-invalid")).to eq(false)
      expect(input.key?("aria-errormessage")).to eq(false)
    end

    it "marks an invalid radio button in a non-new form and associates it with error messages" do
      form_class = Class.new(Brut::FrontEnd::Form) { radio_button_group :size }
      form = form_class.new(params: { size: "" })

      input = input_from(described_class.new(form:, input_name: :size, value: "small").call)

      expect(input["aria-invalid"]).to eq("true")
      expect(input["aria-errormessage"]).not_to eq(nil)
      expect(input["aria-errormessage"]).to match(/\S/)
    end

    it "does not mark a valid radio button in a non-new form as invalid" do
      form_class = Class.new(Brut::FrontEnd::Form) { radio_button_group :size }
      form = form_class.new(params: { size: "small" })

      input = input_from(described_class.new(form:, input_name: :size, value: "small").call)

      expect(input.key?("aria-invalid")).to eq(false)
      expect(input.key?("aria-errormessage")).to eq(false)
    end

    it "does not mark a radio button with a server-side violation invalid on a new form" do
      form_class = Class.new(Brut::FrontEnd::Form) { radio_button_group :size, required: false }
      form = form_class.new
      form.server_side_constraint_violation(input_name: :size, key: :not_available)

      input = input_from(described_class.new(form:, input_name: :size, value: "small").call)

      expect(form.input(:size).validity_state).not_to have_constraint_violation(:valueMissing)
      expect(input.key?("aria-invalid")).to eq(false)
      expect(input.key?("aria-errormessage")).to eq(false)
    end
  end

  describe "#invalid?" do
    it "is true when the radio button is rendered invalid" do
      form_class = Class.new(Brut::FrontEnd::Form) { radio_button_group :size }
      form = form_class.new(params: { size: "" })
      component = described_class.new(form:, input_name: :size, value: "small")
      component.call

      expect(component.invalid?).to eq(true)
    end

    it "is false for a required radio button in a new form" do
      form_class = Class.new(Brut::FrontEnd::Form) { radio_button_group :size }
      form = form_class.new
      component = described_class.new(form:, input_name: :size, value: "small")
      component.call

      expect(component.invalid?).to eq(false)
    end

    it "is false for a new form with a server-side violation" do
      form_class = Class.new(Brut::FrontEnd::Form) { radio_button_group :size, required: false }
      form = form_class.new
      form.server_side_constraint_violation(input_name: :size, key: :not_available)
      component = described_class.new(form:, input_name: :size, value: "small")
      component.call

      expect(component.invalid?).to eq(false)
    end

    it "is false for a valid radio button in a non-new form" do
      form_class = Class.new(Brut::FrontEnd::Form) { radio_button_group :size }
      form = form_class.new(params: { size: "small" })
      component = described_class.new(form:, input_name: :size, value: "small")
      component.call

      expect(component.invalid?).to eq(false)
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
