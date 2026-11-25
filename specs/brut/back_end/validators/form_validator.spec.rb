require "spec_helper"

RSpec.describe Brut::BackEnd::Validators::FormValidator do
  class TestForm < Brut::FrontEnd::Form
    input :name
    input :code
  end

  class NonLengthValueForm < Brut::FrontEnd::Form
    input :name
    input :code

    def code = 123
  end

  class RequiredNameValidator < Brut::BackEnd::Validators::FormValidator
    validate :name, required: true
  end

  class MinlengthCodeValidator < Brut::BackEnd::Validators::FormValidator
    validate :code, minlength: 5
  end

  describe "#validate" do
    it "records a required violation when a required value is blank" do
      form = TestForm.new(params: { name: "", code: "long enough" })

      RequiredNameValidator.new.validate(form)

      expect(form.input(:name).validity_state).to have_constraint_violation(:required)
    end

    it "does not record a required violation when the value is present" do
      form = TestForm.new(params: { name: "Dave", code: "long enough" })

      RequiredNameValidator.new.validate(form)

      expect(form.input(:name).validity_state).not_to have_constraint_violation(:required)
    end

    it "records a too_short violation with minlength in the context" do
      form = TestForm.new(params: { name: "Dave", code: "abcd" })

      MinlengthCodeValidator.new.validate(form)

      violations = form.input(:code).validity_state
      expect(violations).to have_constraint_violation(:too_short)
      expect(violations.detect { it.key == "too_short" }.context).to eq({ minlength: 5 })
    end

    it "does not record a too_short violation when the value meets the minlength" do
      form = TestForm.new(params: { name: "Dave", code: "abcde" })

      MinlengthCodeValidator.new.validate(form)

      expect(form.input(:code).validity_state).not_to have_constraint_violation(:too_short)
    end

    it "raises when minlength is used on a value that does not respond to length" do
      form = NonLengthValueForm.new(params: { name: "Dave", code: "abcde" })

      expect {
        MinlengthCodeValidator.new.validate(form)
      }.to raise_error(RuntimeError, /does not respond to 'length'/)
    end

    it "does not apply validations declared on a sibling validator" do
      form = TestForm.new(params: { name: "Dave", code: "abcd" })

      RequiredNameValidator.new.validate(form)

      expect(form.input(:code).validity_state).not_to have_constraint_violation(:too_short)
    end

    it "does nothing when the validator declares no validations" do
      form = TestForm.new(params: { name: "", code: "abcd" })
      validator_class = Class.new(Brut::BackEnd::Validators::FormValidator)

      validator_class.new.validate(form)

      expect(form.input(:name).validity_state).not_to have_constraint_violation(:required)
      expect(form.input(:code).validity_state).not_to have_constraint_violation(:too_short)
    end
  end
end
