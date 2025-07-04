require "spec_helper"

RSpec.describe Brut::FrontEnd::Forms::RadioButtonGroupInput do
  describe "#value=" do
    let(:name) { "test-input" }
    context "value is present" do
      it "does not set any violations" do
        input = described_class.new(
          input_definition: Brut::FrontEnd::Forms::RadioButtonGroupInputDefinition.new(
            name:,
            required: true,
          ),
          index: 0,
          value: "DC"
        )
        expect(input.valid?).to eq(true)
        expect(input.value).to eq("DC")
        expect(input.typed_value).to eq("DC")
      end
    end
    context "value is not present" do
      context "required" do
        it "sets valueMissing violation" do
          input = described_class.new(
            input_definition: Brut::FrontEnd::Forms::RadioButtonGroupInputDefinition.new(
              name:,
              required: true,
            ),
            index: 0,
            value: ""
          )
          expect(input.validity_state).to have_constraint_violation(:valueMissing)
          expect(input.value).to eq("")
          expect(input.typed_value).to eq(nil)
        end
      end
      context "not required" do
        it "does not set any violations" do
          input = described_class.new(
            input_definition: Brut::FrontEnd::Forms::RadioButtonGroupInputDefinition.new(
              name:,
              required: false,
            ),
            index: 0,
            value: ""
          )
          expect(input.valid?).to eq(true)
          expect(input.value).to eq("")
          expect(input.typed_value).to eq(nil)
        end
      end
    end
  end
end
