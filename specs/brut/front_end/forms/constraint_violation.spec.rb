require "spec_helper"

RSpec.describe Brut::FrontEnd::Forms::ConstraintViolation do
  describe "#initialize" do
    it "converts the key to a string" do
      violation = described_class.new(key: :taken, context: {})

      expect(violation.key).to eq("taken")
    end

    it "treats nil context as an empty hash" do
      violation = described_class.new(key: :taken, context: nil)

      expect(violation.context).to eq({})
    end

    it "keeps a hash context as-is" do
      context = { field: "Name", minlength: 5 }

      violation = described_class.new(key: :too_short, context:)

      expect(violation.context).to eq(context)
      expect(violation.context).to be(context)
    end

    it "raises when the context is not a hash or nil" do
      expect {
        described_class.new(key: :taken, context: "not a hash")
      }.to raise_error(RuntimeError, /Context must be nil or a hash/)
    end

    context "server_side is :based_on_key" do
      it "is client-side for a browser ValidityState key" do
        violation = described_class.new(key: :valueMissing, context: {})

        expect(violation.client_side?).to eq(true)
      end

      it "is not client-side for an arbitrary server-side key" do
        violation = described_class.new(key: :taken, context: {})

        expect(violation.client_side?).to eq(false)
      end
    end

    context "server_side is true" do
      it "is not client-side even for a browser ValidityState key" do
        violation = described_class.new(
          key: :valueMissing,
          context: {},
          server_side: true,
        )

        expect(violation.client_side?).to eq(false)
      end

      it "is not client-side for an arbitrary server-side key" do
        violation = described_class.new(
          key: :taken,
          context: {},
          server_side: true,
        )

        expect(violation.client_side?).to eq(false)
      end
    end

    context "server_side is false" do
      it "still treats browser ValidityState keys as client-side" do
        violation = described_class.new(
          key: :valueMissing,
          context: {},
          server_side: false,
        )

        expect(violation.client_side?).to eq(true)
      end
    end
  end

  describe "#to_s" do
    it "returns the key" do
      violation = described_class.new(key: :taken, context: {})

      expect(violation.to_s).to eq("taken")
    end
  end
end
