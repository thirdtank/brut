require "spec_helper"
require "nokogiri"

RSpec.describe Brut::FrontEnd::Components::Inputs::SelectTagWithOptions do

  before do
    span = double(add_prefixed_attributes: nil)
    instrumentation = double
    allow(instrumentation).to receive(:span) { |_name, &block| block.call(span) }

    container = Brut::Framework::Container.new
    container.store("instrumentation", Object, "Instrumentation", instrumentation)
    allow(Brut).to receive(:container).and_return(container)
  end

  def select_from(html) = Nokogiri::HTML5(html).at_css("select")
  def options_from(html) = Nokogiri::HTML5(html).css("select option")

  describe "generating HTML" do
    it "generates the select's name and required, plus options with their values and text, selecting the matching option" do
      option_class = Struct.new(:value, :text)
      options = [
        option_class.new("small", "Small"),
        option_class.new("large", "Large"),
      ]
      form_class = Class.new(Brut::FrontEnd::Form) { select :size }
      form = form_class.new(params: { size: "large" })

      html = described_class.new(
        form:,
        input_name: :size,
        options:,
        value_attribute: :value,
        option_text_attribute: :text
      ).call

      select = select_from(html)
      rendered_options = options_from(html)

      expect(select["name"]).to          eq("size")
      expect(select.key?("required")).to eq(true)

      expect(rendered_options.map { it["value"] }).to eq(["small", "large"])
      expect(rendered_options.map(&:text)).to         eq(["Small", "Large"])
      expect(rendered_options[0].key?("selected")).to eq(false)
      expect(rendered_options[1].key?("selected")).to eq(true)
    end

    it "generates no selected option when the form has no value" do
      option_class = Struct.new(:value, :text)
      options = [option_class.new("small", "Small")]
      form_class = Class.new(Brut::FrontEnd::Form) { select :size }
      form = form_class.new(params: {})

      rendered_options = options_from(
        described_class.new(
          form:,
          input_name: :size,
          options:,
          value_attribute: :value,
          option_text_attribute: :text
        ).call
      )

      expect(rendered_options[0].key?("selected")).to eq(false)
    end

    it "generates a blank option with no value or text when include_blank is true" do
      option_class = Struct.new(:value, :text)
      options = [option_class.new("small", "Small")]
      form_class = Class.new(Brut::FrontEnd::Form) { select :size }
      form = form_class.new(params: {})

      rendered_options = options_from(
        described_class.new(
          form:,
          input_name: :size,
          options:,
          value_attribute: :value,
          option_text_attribute: :text,
          include_blank: true
        ).call
      )

      expect(rendered_options.length).to        eq(2)
      expect(rendered_options[0].key?("value")).to eq(false)
      expect(rendered_options[0].text).to        eq("")
      expect(rendered_options[1]["value"]).to    eq("small")
    end

    it "generates a blank option with the given value and text when include_blank is a Hash" do
      option_class = Struct.new(:value, :text)
      options = [option_class.new("small", "Small")]
      form_class = Class.new(Brut::FrontEnd::Form) { select :size }
      form = form_class.new(params: {})

      rendered_options = options_from(
        described_class.new(
          form:,
          input_name: :size,
          options:,
          value_attribute: :value,
          option_text_attribute: :text,
          include_blank: { value: "", text_content: "Choose one" }
        ).call
      )

      expect(rendered_options.length).to       eq(2)
      expect(rendered_options[0]["value"]).to  eq("")
      expect(rendered_options[0].text).to      eq("Choose one")
    end

    it "omits required when the select is not required" do
      option_class = Struct.new(:value, :text)
      options = [option_class.new("small", "Small")]
      form_class = Class.new(Brut::FrontEnd::Form) { select :size, required: false }
      form = form_class.new(params: { size: "small" })

      select = select_from(
        described_class.new(
          form:,
          input_name: :size,
          options:,
          value_attribute: :value,
          option_text_attribute: :text
        ).call
      )

      expect(select.key?("required")).to eq(false)
    end

    it "merges extra HTML attributes last, allowing them to override generated ones" do
      option_class = Struct.new(:value, :text)
      options = [option_class.new("small", "Small")]
      form_class = Class.new(Brut::FrontEnd::Form) { select :size }
      form = form_class.new(params: { size: "small" })

      select = select_from(
        described_class.new(
          form:,
          input_name: :size,
          options:,
          value_attribute: :value,
          option_text_attribute: :text,
          html_attributes: { class: "big", "data-testid" => "size-select" }
        ).call
      )

      expect(select["class"]).to       eq("big")
      expect(select["data-testid"]).to eq("size-select")
      expect(select["name"]).to        eq("size")
    end

    it "raises if a multi-select is used" do
      option_class = Struct.new(:value, :text)
      options = [
        option_class.new("small", "Small"),
        option_class.new("large", "Large"),
      ]
      form_class = Class.new(Brut::FrontEnd::Form) { select :size }
      form = form_class.new(params: { size: "small" })

      expect {
        described_class.new(
          form:,
          input_name: :size,
          options:,
          value_attribute: :value,
          option_text_attribute: :text,
          html_attributes: { multiple: true }
        ).call
      }.to raise_error(ArgumentError,/not supported/)
    end
  end

  describe "matching values" do
    it "renders an option's value as the String it uses to match, and selects it" do
      id_class = Struct.new(:numeric, :metadata) do 
        def to_s = self.numeric.to_s
      end
      option_class = Struct.new(:id, :name)
      options = [
        option_class.new(
          id: id_class.new(
            numeric: 42,
            metadata: {},
          ),
          name: "The Option",
        ),
      ]
      form_class = Class.new(Brut::FrontEnd::Form) { select :size }
      form = form_class.new(params: { size: 42 })

      option = options_from(
        described_class.new(
          form:,
          input_name: :size,
          options:,
          value_attribute: :id,
          option_text_attribute: :name
        ).call
      ).first

      expect(option["value"]).to         eq("42")
      expect(option.key?("selected")).to eq(true)
    end

    it "raises when the form's value does not match any option" do
      option_class = Struct.new(:value, :text)
      options = [option_class.new("small", "Small")]
      form_class = Class.new(Brut::FrontEnd::Form) { select :size }
      form = form_class.new(params: { size: "huge" })

      expect {
        described_class.new(
          form:,
          input_name: :size,
          options:,
          value_attribute: :value,
          option_text_attribute: :text
        ).call
      }.to raise_error(ArgumentError, /was not the value/)
    end

    it "does not raise when the blank option's value was submitted" do
      option_class = Struct.new(:value, :text)
      options = [option_class.new("small", "Small")]
      form_class = Class.new(Brut::FrontEnd::Form) { select :size }
      form = form_class.new(params: { size: "none" })

      expect {
        described_class.new(
          form:,
          input_name: :size,
          options:,
          value_attribute: :value,
          option_text_attribute: :text,
          include_blank: { value: "none", text_content: "None" }
        ).call
      }.not_to raise_error
    end
  end

  describe "array inputs" do
    it "uses the [] suffix in the name and selects the value at the given index" do
      option_class = Struct.new(:value, :text)
      options = [
        option_class.new("small", "Small"),
        option_class.new("large", "Large"),
      ]
      form_class = Class.new(Brut::FrontEnd::Form) { select :size, array: true }
      form = form_class.new(params: { size: ["small", "large"] })

      first_html = described_class.new(
        form:,
        input_name: :size,
        options:,
        value_attribute: :value,
        option_text_attribute: :text,
        index: 0
      ).call
      second_html = described_class.new(
        form:,
        input_name: :size,
        options:,
        value_attribute: :value,
        option_text_attribute: :text,
        index: 1
      ).call

      first_select  = select_from(first_html)
      second_select = select_from(second_html)
      first_options  = options_from(first_html)
      second_options = options_from(second_html)

      expect(first_select["name"]).to  eq("size[]")
      expect(second_select["name"]).to eq("size[]")

      expect(first_options[0].key?("selected")).to  eq(true)
      expect(first_options[1].key?("selected")).to  eq(false)
      expect(second_options[0].key?("selected")).to eq(false)
      expect(second_options[1].key?("selected")).to eq(true)
    end

    it "raises when an array input is not given an index" do
      option_class = Struct.new(:value, :text)
      options = [option_class.new("small", "Small")]
      form_class = Class.new(Brut::FrontEnd::Form) { select :size, array: true }
      form = form_class.new(params: { size: ["small"] })

      expect {
        described_class.new(
          form:,
          input_name: :size,
          options:,
          value_attribute: :value,
          option_text_attribute: :text
        ).call
      }.to raise_error(ArgumentError, /index/)
    end
  end

  describe "invalid usage" do
    it "raises when used with an input that is not a select" do
      option_class = Struct.new(:value, :text)
      options = [option_class.new("small", "Small")]
      form_class = Class.new(Brut::FrontEnd::Form) { input :size }
      form = form_class.new(params: { size: "small" })

      expect {
        described_class.new(
          form:,
          input_name: :size,
          options:,
          value_attribute: :value,
          option_text_attribute: :text
        ).call
      }.to raise_error(ArgumentError, /can only be used with .*select/i)
    end

    it "raises when a non-array input is given a non-zero index, but allows index 0" do
      option_class = Struct.new(:value, :text)
      options = [option_class.new("small", "Small")]
      form_class = Class.new(Brut::FrontEnd::Form) { select :size }
      form = form_class.new(params: { size: "small" })

      expect {
        described_class.new(
          form:,
          input_name: :size,
          options:,
          value_attribute: :value,
          option_text_attribute: :text,
          index: 1
        ).call
      }.to raise_error(ArgumentError, /index/)

      select = select_from(
        described_class.new(
          form:,
          input_name: :size,
          options:,
          value_attribute: :value,
          option_text_attribute: :text,
          index: 0
        ).call
      )
      expect(select["name"]).to eq("size")
    end
  end
end
