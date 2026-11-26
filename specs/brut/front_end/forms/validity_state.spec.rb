require "spec_helper"

RSpec.describe Brut::FrontEnd::Forms::ValidityState do
  describe "#initialize" do
    it "is valid with no constraint violations" do
      validity_state = described_class.new

      expect(validity_state.valid?).to eq(true)
      expect(validity_state.constraint_violations?).to eq(false)
      expect(validity_state.to_a).to eq([])
    end

    it "creates a ConstraintViolation for each truthy entry" do
      validity_state = described_class.new(
        valueMissing: true,
        tooShort: false,
        tooLong: nil,
      )

      expect(validity_state.constraint_violations?).to eq(true)
      expect(validity_state.map(&:key)).to eq(["valueMissing"])
    end

    it "treats any truthy value as a violation" do
      validity_state = described_class.new(valueMissing: "yes")

      expect(validity_state.map(&:key)).to eq(["valueMissing"])
    end

    it "converts keys to strings" do
      validity_state = described_class.new(valueMissing: true)

      expect(validity_state.first.key).to eq("valueMissing")
    end

    it "marks known browser keys as client-side and arbitrary keys as server-side" do
      validity_state = described_class.new(
        valueMissing: true,
        taken: true,
      )

      client_side = validity_state.detect { it.key == "valueMissing" }
      server_side = validity_state.detect { it.key == "taken" }

      expect(client_side.client_side?).to eq(true)
      expect(server_side.client_side?).to eq(false)
    end

    it "preserves the insertion order of the violations" do
      validity_state = described_class.new(
        tooLong: true,
        valueMissing: true,
        patternMismatch: true,
      )

      expect(validity_state.map(&:key)).to eq([
        "tooLong",
        "valueMissing",
        "patternMismatch",
      ])
    end
  end

  describe "#valid?" do
    it "is true when there are no violations" do
      expect(described_class.new.valid?).to eq(true)
    end

    it "is false when there is a client-side violation" do
      expect(described_class.new(valueMissing: true).valid?).to eq(false)
    end

    it "is false when there is a server-side violation" do
      validity_state = described_class.new
      validity_state.server_side_constraint_violation(key: :taken, context: {})

      expect(validity_state.valid?).to eq(false)
    end
  end

  describe "#constraint_violations?" do
    it "is the inverse of valid?" do
      validity_state = described_class.new
      expect(validity_state.constraint_violations?).to eq(false)

      validity_state.server_side_constraint_violation(key: :taken, context: {})
      expect(validity_state.constraint_violations?).to eq(true)
    end
  end

  describe "#server_side_constraint_violation" do
    it "appends a server-side violation" do
      validity_state = described_class.new
      validity_state.server_side_constraint_violation(
        key: :taken,
        context: { value: "Dave" },
      )

      violation = validity_state.first

      expect(violation.key).to eq("taken")
      expect(violation.context).to eq({ value: "Dave" })
      expect(violation.client_side?).to eq(false)
    end

    it "forces a known browser key to be server-side" do
      validity_state = described_class.new
      validity_state.server_side_constraint_violation(
        key: :valueMissing,
        context: {},
      )

      expect(validity_state.first.client_side?).to eq(false)
    end

    it "preserves existing client-side violations" do
      validity_state = described_class.new(valueMissing: true)
      validity_state.server_side_constraint_violation(key: :taken, context: {})

      expect(validity_state.map(&:key)).to eq(["valueMissing", "taken"])
    end

    it "raises when the context is not a hash or nil" do
      validity_state = described_class.new

      expect {
        validity_state.server_side_constraint_violation(
          key: :taken,
          context: "not a hash",
        )
      }.to raise_error(RuntimeError, /Context must be nil or a hash/)
    end
  end

  describe "#each" do
    it "yields each constraint violation in order" do
      validity_state = described_class.new(
        valueMissing: true,
        taken: true,
      )

      yielded = []
      validity_state.each { |violation| yielded << violation.key }

      expect(yielded).to eq(["valueMissing", "taken"])
    end
  end

  describe "Enumerable behavior" do
    it "supports map and select" do
      validity_state = described_class.new(
        valueMissing: true,
        taken: true,
      )

      expect(validity_state.map(&:key)).to eq(["valueMissing", "taken"])
      expect(validity_state.select(&:client_side?).map(&:key)).to eq(["valueMissing"])
    end
  end
end
