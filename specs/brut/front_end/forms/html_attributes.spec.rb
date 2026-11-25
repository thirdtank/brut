require "spec_helper"

RSpec.describe Brut::FrontEnd::Forms::HtmlAttributes do

  describe "#initialize" do
    it "sets the name from the input" do
      form_class = Class.new(Brut::FrontEnd::Form) { input :title }
      input = form_class.new(params: {}).input(:title)

      attributes = described_class.new(input:)

      expect(attributes.to_h).to eq(name: "title")
    end

    it "appends [] to the name for array inputs" do
      form_class = Class.new(Brut::FrontEnd::Form) { input :tags, array: true }
      input = form_class.new(params: {}).input(:tags, index: 0)

      attributes = described_class.new(input:)

      expect(attributes.to_h).to eq(name: "tags[]")
    end

    it "downcases and symbolizes initial attribute names, leaving their values alone" do
      form_class = Class.new(Brut::FrontEnd::Form) { input :title }
      input = form_class.new(params: {}).input(:title)

      attributes = described_class.new(
        input:,
        initial_attributes: { "CLASS" => "Big", "DATA-TESTID" => "the-title" }
      )

      expect(attributes.to_h).to eq(
        class: "Big",
        :"data-testid" => "the-title",
        name: "title",
      )
    end

    it "does not let initial attributes override the name" do
      form_class = Class.new(Brut::FrontEnd::Form) { input :title }
      input = form_class.new(params: {}).input(:title)

      attributes = described_class.new(
        input:,
        initial_attributes: { name: "override", "NAME" => "another-override" }
      )

      expect(attributes.to_h[:name]).to eq("title")
    end

    it "raises when a forbidden attribute is present" do
      form_class = Class.new(Brut::FrontEnd::Form) { input :size }
      input = form_class.new(params: {}).input(:size)

      expect {
        described_class.new(
          input:,
          initial_attributes: { "MULTIPLE" => true },
          forbidden_attributes: { multiple: "Multi-selects are not supported by Brut" }
        )
      }.to raise_error(ArgumentError, "Multi-selects are not supported by Brut")
    end

    it "raises with every explanation when multiple forbidden attributes are present" do
      form_class = Class.new(Brut::FrontEnd::Form) { input :size }
      input = form_class.new(params: {}).input(:size)

      expect {
        described_class.new(
          input:,
          initial_attributes: { multiple: true, accept: "text/plain" },
          forbidden_attributes: {
            multiple: "Multi-selects are not supported by Brut",
            accept: "The accept attribute is not supported",
          }
        )
      }.to raise_error(
        ArgumentError,
        "Multi-selects are not supported by Brut, The accept attribute is not supported"
      )
    end

    it "does not raise when no forbidden attribute is present" do
      form_class = Class.new(Brut::FrontEnd::Form) { input :size }
      input = form_class.new(params: {}).input(:size)

      expect {
        described_class.new(
          input:,
          initial_attributes: { class: "big" },
          forbidden_attributes: { multiple: "Multi-selects are not supported by Brut" }
        )
      }.not_to raise_error
    end

    it "normalizes forbidden attribute names like the other attribute names" do
      form_class = Class.new(Brut::FrontEnd::Form) { input :size }
      input = form_class.new(params: {}).input(:size)

      expect {
        described_class.new(
          input:,
          initial_attributes: { multiple: true },
          forbidden_attributes: { "MULTIPLE" => "Multi-selects are not supported by Brut" }
        )
      }.to raise_error(ArgumentError, "Multi-selects are not supported by Brut")
    end
  end

  describe "#with_defaults" do
    it "adds defaults for missing attributes, lets initial attributes win, normalizes both, and returns itself" do
      form_class = Class.new(Brut::FrontEnd::Form) { input :title }
      input = form_class.new(params: {}).input(:title)

      attributes = described_class.new(
        input:,
        initial_attributes: { "REQUIRED" => false, class: "big" }
      )

      result = attributes.with_defaults do |defaults|
        defaults["REQUIRED"] = true
        defaults[:TYPE] = "text"
        defaults[:class] = "default"
      end

      expect(result).to be(attributes)
      expect(result.to_h).to eq(
        required: false,
        type: "text",
        class: "big",
        name: "title",
      )
    end
  end

  describe "#to_hash" do
    it "is the same as to_h" do
      form_class = Class.new(Brut::FrontEnd::Form) { input :title }
      input = form_class.new(params: {}).input(:title)
      attributes = described_class.new(input:, initial_attributes: { class: "big" })

      expect(attributes.to_hash).to eq(attributes.to_h)
    end
  end
end
