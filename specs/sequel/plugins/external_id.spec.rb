require "spec_helper"

RSpec.describe "Sequel::Plugins::ExternalId" do

  let(:columns) { [:id, :name, :external_id, :created_at, :kind] }

  let(:db) {
    Sequel.mock(
      host: :postgres,
      columns:[:id, :name, :external_id, :created_at, :kind],
      numrows: 0
    )
  }

  let(:model_with_external_id) {
    model = Class.new(Sequel::Model(db[:widgets]))
    model.plugin :external_id, global_prefix: "my"
    model.has_external_id "wg"
    model
  }

  describe "loading as a Sequel plugin" do
    it "loads through Sequel's plugin mechanism and generates external ids" do
      model = Class.new(Sequel::Model(db[:widgets]))

      model.plugin :external_id, global_prefix: "my"
      model.has_external_id "wg"

      widget = model.new(name: "x")
      widget.save

      expect(widget.external_id).to match(/\Amywg_[0-9a-f]{32}\z/)
    end

    it "uses the latest options when Sequel loads the plugin again" do
      model = Class.new(Sequel::Model(db[:widgets]))
      model.plugin :external_id, global_prefix: "first"
      model.plugin :external_id, global_prefix: "second"
      model.has_external_id "wg"

      widget = model.new(name: "x")
      widget.save

      expect(widget.external_id).to match(/\Asecondwg_[0-9a-f]{32}\z/)
    end

    it "keeps global prefix configuration with each model class" do
      widget_model = Class.new(Sequel::Model(db[:widgets]))
      gadget_model = Class.new(Sequel::Model(db[:widgets]))
      widget_model.plugin :external_id, global_prefix: "wg"
      gadget_model.plugin :external_id, global_prefix: "gd"
      widget_model.has_external_id "w"
      gadget_model.has_external_id "g"

      widget = widget_model.new(name: "x")
      gadget = gadget_model.new(name: "y")
      widget.save
      gadget.save

      expect(widget.external_id).to match(/\Awgw_[0-9a-f]{32}\z/)
      expect(gadget.external_id).to match(/\Agdg_[0-9a-f]{32}\z/)
    end

    it "composes with before_save hooks loaded after it" do
      model = Class.new(Sequel::Model(db[:widgets]))
      model.plugin :external_id, global_prefix: "my"
      model.plugin :created_at
      model.has_external_id "wg"

      widget = model.new(name: "x")
      widget.save

      expect(widget.external_id).to match(/\Amywg_[0-9a-f]{32}\z/)
      expect(widget.created_at).not_to eq(nil)
    end

    it "composes with before_save hooks loaded before it" do
      model = Class.new(Sequel::Model(db[:widgets]))
      model.plugin :created_at
      model.plugin :external_id, global_prefix: "my"
      model.has_external_id "wg"

      widget = model.new(name: "x")
      widget.save

      expect(widget.external_id).to match(/\Amywg_[0-9a-f]{32}\z/)
      expect(widget.created_at).not_to eq(nil)
    end
  end

  describe "configuring a model's prefix" do
    it "prepends the global prefix and the model prefix" do
      model = model_with_external_id

      widget = model.new(name: "x")
      widget.save

      expect(widget.external_id).to match(/\Amywg_[0-9a-f]{32}\z/)
      expect(db.sqls.join).to include(widget.external_id)
    end

    it "accepts a Symbol for the model prefix" do
      model = Class.new(Sequel::Model(db[:widgets]))
      model.plugin :external_id, global_prefix: "my"
      model.has_external_id :ac

      widget = model.new(name: "x")
      widget.save

      expect(widget.external_id).to match(/\Amyac_[0-9a-f]{32}\z/)
    end

    it "uses only the model prefix when no global prefix is configured" do
      model = Class.new(Sequel::Model(db[:widgets]))
      model.plugin :external_id
      model.has_external_id "wg"

      widget = model.new(name: "x")
      widget.save

      expect(widget.external_id).to match(/\Awg_[0-9a-f]{32}\z/)
    end

    context "when there is no global prefix" do
      context "when there is no external id" do
        let(:global_prefix) { nil }
        it "does not generate an external id" do
          model = Class.new(Sequel::Model(db[:widgets]))
          model.plugin :external_id, global_prefix: nil
          model.has_external_id ""

          widget = model.new(name: "x")
          widget.save

          expect(widget.external_id).to eq(nil)
        end
      end
      context "when there is an external id" do
        it "generates an external id using just the models' prefix" do
          model = Class.new(Sequel::Model(db[:widgets]))
          model.plugin :external_id, global_prefix: nil
          model.has_external_id "wg"

          widget = model.new(name: "x")
          widget.save

          expect(widget.external_id).to match(/^wg_/)
        end
      end
    end

    it "inherits the prefix on a model subclass" do
      parent = model_with_external_id
      child = Class.new(parent)

      widget = child.new(name: "x")
      widget.save

      expect(widget.external_id).to match(/\Amywg_[0-9a-f]{32}\z/)
    end

    it "allows a model subclass to override the prefix" do
      parent = model_with_external_id
      child = Class.new(parent)
      child.has_external_id "sw"

      widget = child.new(name: "x")
      widget.save

      expect(widget.external_id).to match(/\Amysw_[0-9a-f]{32}\z/)
    end
  end

  describe "saving a model" do
    it "does not overwrite an explicit external id" do
      model = model_with_external_id

      widget = model.new(name: "x", external_id: "mywg_explicit")
      widget.save

      expect(widget.external_id).to eq("mywg_explicit")
    end

    it "does not change an existing external id on update" do
      db = Sequel.mock(
        host: :postgres,
        columns:,
        numrows: 1,
      )
      model = Class.new(Sequel::Model(db[:widgets]))
      model.plugin :external_id, global_prefix: "my"
      model.has_external_id "wg"

      widget = model.load(id: 1, name: "x", external_id: "mywg_existing")

      widget.update(name: "y")

      expect(widget.external_id).to eq("mywg_existing")
    end

    it "generates an external id when updating a record that does not have one" do
      db = Sequel.mock(
        host: :postgres,
        columns:,
        numrows: 1,
      )
      model = Class.new(Sequel::Model(db[:widgets]))
      model.plugin :external_id, global_prefix: "my"
      model.has_external_id "wg"
      widget = model.load(id: 1, name: "x", external_id: nil)

      widget.update(name: "y")

      expect(widget.external_id).to match(/\Amywg_[0-9a-f]{32}\z/)
    end

    it "generates a distinct external id for each record" do
      model = Class.new(Sequel::Model(db[:widgets]))
      model.plugin :external_id, global_prefix: "my"
      model.has_external_id "wg"
      first = model.new(name: "x")
      second = model.new(name: "y")

      first.save
      second.save

      expect(first.external_id).not_to eq(second.external_id)
    end

    it "does not set an external id on models that did not call has_external_id" do
      model = Class.new(Sequel::Model(db[:widgets]))
      model.plugin :external_id, global_prefix: "my"

      widget = model.new(name: "x")
      widget.save

      expect(widget.external_id).to eq(nil)
    end

    it "does not require tables to have an external_id column" do
      db = Sequel.mock(
        host: :postgres,
        columns: [ :id, :name, :created_at ],
        numrows: 0,
      )
      model = Class.new(Sequel::Model(db[:widgets]))
      model.plugin :external_id, global_prefix: "my"

      widget = model.new(name: "x")
      widget.save

      expect(widget.name).to eq("x")
      expect(db.sqls.join).to include("INSERT INTO \"widgets\"")
    end

    it "works with Sequel's single table inheritance" do
      base = Class.new(Sequel::Model(db[:widgets]))
      stub_const("ExternalIdSpecWidget", base)
      base.plugin :single_table_inheritance, :kind
      base.plugin :external_id, global_prefix: "my"
      base.has_external_id "wg"
      stub_const("ExternalIdSpecSpecialWidget", Class.new(base))

      widget = ExternalIdSpecSpecialWidget.new(name: "x")
      widget.save

      expect(widget.kind).to eq("ExternalIdSpecSpecialWidget")
      expect(widget.external_id).to match(/\Amywg_[0-9a-f]{32}\z/)
    end
  end

  describe "#to_s" do
    it "includes the external id after the value from the superclass" do
      model = model_with_external_id
      widget = model.new(name: "x")

      widget.save

      expect(widget.to_s).to end_with("[external_id:#{widget.external_id}]")
    end
  end
end
