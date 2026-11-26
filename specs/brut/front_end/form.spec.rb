require "spec_helper"

RSpec.describe Brut::FrontEnd::Form do
  let(:rack_env) { "test" }
  let(:instrumentation) { double("instrumentation", add_attributes: nil, add_event: nil) }
  let(:project_env) { Brut::Framework::ProjectEnvironment.new(rack_env) }

  before do
    container = Brut::Framework::Container.new
    container.store("instrumentation", Object, "Instrumentation", instrumentation)
    container.store("project_env", Brut::Framework::ProjectEnvironment, "Project environment", project_env)
    allow(Brut).to receive(:container).and_return(container)
  end

  let(:form_class) {
    Class.new(Brut::FrontEnd::Form) do
      input :name, required: false
    end
  }

  describe ".routing" do
    it "raises because forms must be registered with a route" do
      expect {
        described_class.routing
      }.to raise_error(ArgumentError, /hasn't been configured/)
    end
  end

  describe "#initialize" do
    it "converts values to the strings expected by form inputs" do
      form_class = Class.new(Brut::FrontEnd::Form) do
        input :title, required: false
        input :count, type: "number", required: false
        input :enabled, required: false
        input :disabled, required: false
        input :nothing, required: false
        input :blank, required: false
      end

      form = form_class.new(params: {
        title: "Hello",
        count: 10,
        enabled: true,
        disabled: false,
        nothing: nil,
        blank: "   ",
      })

      expect(form.to_h).to eq(
        "title" => "Hello",
        "count" => "10",
        "enabled" => "true",
        "disabled" => "false",
        "nothing" => nil,
        "blank" => nil,
      )
    end

    it "converts symbol keys to strings" do
      form = form_class.new(params: { name: "Dave" })

      expect(form.to_h).to eq("name" => "Dave")
    end

    it "drops unknown params and instruments them" do
      form = form_class.new(params: {
        name: "Dave",
        unknown: "one",
        another: "two",
      })

      expect(form.to_h).to eq("name" => "Dave")
      expect(instrumentation).to have_received(:add_attributes).with(
        prefix: :brut,
        ignored_unknown_params: "unknown,another",
      )
    end

    it "raises for unsupported param value classes in test" do
      expect {
        form_class.new(params: { name: Object.new })
      }.to raise_error(ArgumentError, /Object/)
    end

    context "outside of test" do
      let(:rack_env) { "development" }

      it "instruments unsupported param value classes and omits the param" do
        expect(instrumentation).to receive(:add_event).with(
          "convert_to_string_or_nil: Unknown class in params hash",
          class: Object,
          key: "name",
        )

        form = form_class.new(params: { name: Object.new })

        expect(form.to_h).to eq({})
      end
    end

    it "converts an array of checkbox indexes into booleans" do
      form_class = Class.new(Brut::FrontEnd::Form) do
        input :tags, type: "checkbox", array: true
      end

      form = form_class.new(params: { tags: ["0", "2"] })

      expect(form.to_h).to eq("tags" => [true, false, true])
      expect(form.inputs(:tags).map(&:typed_value)).to eq([true, false, true])
    end

    it "does not convert checkbox arrays unless every value is an integer string" do
      form_class = Class.new(Brut::FrontEnd::Form) do
        input :tags, type: "checkbox", array: true
      end

      form = form_class.new(params: { tags: ["0", "not-an-index"] })

      expect(form.to_h).to eq("tags" => ["0", "not-an-index"])
    end

    it "does not convert the values of non-checkbox arrays" do
      form_class = Class.new(Brut::FrontEnd::Form) do
        input :items, array: true, required: false
      end

      form = form_class.new(params: { items: [1, "", "   "] })

      expect(form.to_h).to eq("items" => [1, "", "   "])
      expect(form.inputs(:items).map(&:value)).to eq(["1", nil, nil])
    end
  end

  describe "#new?" do
    it "is true with no params" do
      expect(form_class.new.new?).to eq(true)
    end

    it "is true when only unknown params were given" do
      form = form_class.new(params: { unknown: "value" })

      expect(form.new?).to eq(true)
    end

    it "is false when a known param is present, even if its value is blank" do
      expect(form_class.new(params: { name: "" }).new?).to eq(false)
      expect(form_class.new(params: { name: nil }).new?).to eq(false)
    end

    it "is false when a known param has a value" do
      expect(form_class.new(params: { name: "Dave" }).new?).to eq(false)
    end

    it "uses an overridden params_empty?" do
      form_class = Class.new(Brut::FrontEnd::Form) do
        input :name, required: false

        def params_empty?(params)
          true
        end
      end

      form = form_class.new(params: { name: "Dave" })

      expect(form.new?).to eq(true)
    end
  end

  describe "#input" do
    it "returns the same input for string and symbol names" do
      form = form_class.new(params: { name: "Dave" })

      expect(form.input("name")).to be(form.input(:name))
    end

    it "raises for an unknown input" do
      form = form_class.new

      expect {
        form.input(:unknown)
      }.to raise_error(Brut::Framework::Errors::Bug, /does not define the input 'unknown'/)
    end

    it "allows index 0 for a non-array input, but no other index" do
      form = form_class.new(params: { name: "Dave" })

      expect(form.input(:name, index: 0).value).to eq("Dave")
      expect {
        form.input(:name, index: 1)
      }.to raise_error(ArgumentError, /is not an array input/)
    end

    it "requires an index for an array input" do
      form_class = Class.new(Brut::FrontEnd::Form) do
        input :items, array: true, required: false
      end
      form = form_class.new(params: { items: ["one", "two"] })

      expect {
        form.input(:items)
      }.to raise_error(ArgumentError, /is an array input/)
    end

    it "creates and caches an empty input for a missing array index" do
      form_class = Class.new(Brut::FrontEnd::Form) do
        input :items, array: true, required: false
      end
      form = form_class.new(params: { items: ["one"] })

      input = form.input(:items, index: 1)

      expect(input.value).to eq(nil)
      expect(form.input(:items, index: 1)).to be(input)
    end
  end

  describe "#inputs" do
    it "returns all inputs for a name" do
      form_class = Class.new(Brut::FrontEnd::Form) do
        input :items, array: true, required: false
      end
      form = form_class.new(params: { items: ["one", "two"] })

      expect(form.inputs(:items).map(&:value)).to eq(["one", "two"])
    end

    it "raises for an unknown input" do
      form = form_class.new

      expect {
        form.inputs(:unknown)
      }.to raise_error(Brut::Framework::Errors::Bug, /does not define the input 'unknown'/)
    end
  end

  describe "#valid?" do
    it "is true when no inputs have constraint violations" do
      expect(form_class.new.valid?).to eq(true)
    end

    it "is false when an input has a client-side constraint violation" do
      form_class = Class.new(Brut::FrontEnd::Form) { input :name }
      form = form_class.new(params: { name: "" })

      expect(form.valid?).to eq(false)
    end

    it "is false when an input has a server-side constraint violation" do
      form = form_class.new(params: { name: "Dave" })
      form.server_side_constraint_violation(input_name: :name, key: :taken)

      expect(form.valid?).to eq(false)
    end
  end

  describe "#constraint_violations?" do
    it "is the inverse of valid?" do
      valid_form = form_class.new
      invalid_form = Class.new(Brut::FrontEnd::Form) { input :name }.new(params: { name: "" })

      expect(valid_form.constraint_violations?).to eq(false)
      expect(invalid_form.constraint_violations?).to eq(true)
    end
  end

  describe "#server_side_constraint_violation" do
    it "adds a server-side violation to a non-array input" do
      form = form_class.new(params: { name: "Dave" })

      form.server_side_constraint_violation(
        input_name: :name,
        key: :taken,
        context: { value: "Dave" },
      )

      constraint = form.input(:name).validity_state.detect { it.key == "taken" }

      expect(constraint).not_to eq(nil)
      expect(constraint.client_side?).to eq(false)
      expect(constraint.context).to eq({ value: "Dave" })
    end

    it "adds a server-side violation to a specific array index" do
      form_class = Class.new(Brut::FrontEnd::Form) do
        input :items, array: true, required: false
      end
      form = form_class.new(params: { items: ["one", "two"] })

      form.server_side_constraint_violation(
        input_name: :items,
        key: :bad,
        index: 1,
      )

      expect(form.input(:items, index: 0).valid?).to eq(true)
      expect(form.input(:items, index: 1).valid?).to eq(false)
    end

    it "raises when the context is not a Hash or nil" do
      form = form_class.new(params: { name: "Dave" })

      expect {
        form.server_side_constraint_violation(
          input_name: :name,
          key: :taken,
          context: "not a hash",
        )
      }.to raise_error(/Context must be nil or a hash/)
    end
  end

  describe "#constraint_violations" do
    it "returns an empty hash when the form is valid" do
      expect(form_class.new.constraint_violations).to eq({})
    end

    it "returns the violations and index for each invalid input" do
      form_class = Class.new(Brut::FrontEnd::Form) { input :name }
      form = form_class.new(params: { name: "" })

      constraints, index = form.constraint_violations["name"]

      expect(index).to eq(0)
      expect(constraints.map(&:key)).to eq(["valueMissing"])
      expect(constraints).to all(be_client_side)
    end

    it "can return only server-side violations" do
      form_class = Class.new(Brut::FrontEnd::Form) { input :name }
      form = form_class.new(params: { name: "" })
      form.server_side_constraint_violation(input_name: :name, key: :taken)

      constraints, index = form.constraint_violations(server_side_only: true)["name"]

      expect(index).to eq(0)
      expect(constraints.map(&:key)).to eq(["taken"])
      expect(constraints).to all(satisfy { |constraint| !constraint.client_side? })
    end

    it "currently includes client-side-only inputs with an empty violation list when server_side_only is true" do
      form_class = Class.new(Brut::FrontEnd::Form) { input :name }
      form = form_class.new(params: { name: "" })

      constraints, index = form.constraint_violations(server_side_only: true)["name"]

      expect(index).to eq(0)
      expect(constraints).to eq([])
    end

    it "currently returns only the last input when multiple array entries share a name" do
      form_class = Class.new(Brut::FrontEnd::Form) do
        input :items, array: true, required: false
      end
      form = form_class.new(params: { items: ["one", "two"] })
      form.server_side_constraint_violation(input_name: :items, key: :first, index: 0)
      form.server_side_constraint_violation(input_name: :items, key: :second, index: 1)

      constraints, index = form.constraint_violations["items"]

      expect(index).to eq(1)
      expect(constraints.map(&:key)).to eq(["second"])
    end
  end

  describe "#params_empty?" do
    it "is true for nil and empty hashes" do
      form = form_class.new

      expect(form.params_empty?(nil)).to eq(true)
      expect(form.params_empty?({})).to eq(true)
    end

    it "is false for hashes with values" do
      form = form_class.new

      expect(form.params_empty?({ name: "Dave" })).to eq(false)
    end
  end

  describe "#to_h" do
    it "returns only known params with string keys and converted values" do
      form = form_class.new(params: {
        name: "Dave",
        blank: "",
        unknown: "ignored",
      })

      expect(form.to_h).to eq("name" => "Dave")
    end

    it "returns the original array values for array inputs" do
      form_class = Class.new(Brut::FrontEnd::Form) do
        input :items, array: true, required: false
      end
      form = form_class.new(params: { items: [1, "", "   "] })

      expect(form.to_h).to eq("items" => [1, "", "   "])
    end
  end
end
