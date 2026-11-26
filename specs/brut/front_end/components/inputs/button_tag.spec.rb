require "spec_helper"
require "nokogiri"

RSpec.describe Brut::FrontEnd::Components::Inputs::ButtonTag do

  before do
    span = double(add_prefixed_attributes: nil)
    instrumentation = double
    allow(instrumentation).to receive(:span) { |_name, &block| block.call(span) }

    container = Brut::Framework::Container.new
    container.store("instrumentation", Object, "Instrumentation", instrumentation)
    allow(Brut).to receive(:container).and_return(container)
  end

  def button_from(html) = Nokogiri::HTML5(html).at_css("button")

  describe "generating HTML" do
    it "generates the name, a value of 'true' when the form has no value, and the block's content" do
      form_class = Class.new(Brut::FrontEnd::Form) { button :save }
      form = form_class.new(params: {})

      button = button_from(described_class.new(form:, input_name: :save).call { "Save" })

      expect(button["name"]).to  eq("save")
      expect(button["value"]).to eq("true")
      expect(button.text).to     eq("Save")
    end

    it "generates a value of 'true' when the form's value is blank" do
      form_class = Class.new(Brut::FrontEnd::Form) { button :save }
      form = form_class.new(params: { save: "  " })

      button = button_from(described_class.new(form:, input_name: :save).call { "Save" })

      expect(button["value"]).to eq("true")
    end

    it "generates the value submitted with the form, when there is one" do
      form_class = Class.new(Brut::FrontEnd::Form) { button :save }
      form = form_class.new(params: { save: "yes" })

      button = button_from(described_class.new(form:, input_name: :save).call { "Save" })

      expect(button["value"]).to eq("yes")
    end

    it "merges extra HTML attributes last, allowing them to override generated ones" do
      form_class = Class.new(Brut::FrontEnd::Form) { button :save }
      form = form_class.new(params: {})

      button = button_from(
        described_class.new(
          form:,
          input_name: :save,
          value: "override",
          type: "button",
          class: "primary"
        ).call { "Save" }
      )

      expect(button["value"]).to eq("override")
      expect(button["type"]).to  eq("button")
      expect(button["class"]).to eq("primary")
      expect(button.text).to     eq("Save")
    end
  end

  describe "invalid usage" do
    it "raises when used with an input that is not a button" do
      form_class = Class.new(Brut::FrontEnd::Form) { input :name }
      form = form_class.new(params: { name: "Dave" })

      expect {
        described_class.new(form:, input_name: :name).call { "Save" }
      }.to raise_error(Brut::FrontEnd::Components::Inputs::InvalidInputClassForFormInput)
    end

    it "raises when a non-array input is given a non-zero index, but allows index 0" do
      form_class = Class.new(Brut::FrontEnd::Form) { button :save }
      form = form_class.new(params: {})

      expect {
        described_class.new(form:, input_name: :save, index: 1).call { "Save" }
      }.to raise_error(ArgumentError, /index/)

      button = button_from(described_class.new(form:, input_name: :save, index: 0).call { "Save" })
      expect(button["name"]).to  eq("save")
      expect(button["value"]).to eq("true")
    end
  end
end
