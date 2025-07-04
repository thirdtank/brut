require "spec_helper"

RSpec.describe Brut::FrontEnd::Forms::Input do
  describe "#value=" do
    let(:name) { "test-input" }
    [
      "text",
      "search",
      "password",
      "tel",
    ].each do |type|
      context "type=#{type}" do
        context "value is present" do
          let(:input) {
            described_class.new(
              input_definition: Brut::FrontEnd::Forms::InputDefinition.new(
                type:, 
                name:,
                minlength: 5,
                maxlength: 10,
                pattern: "^[0-9]+$",
                required: true,
              ),
              index: 0,
              value: "123456",
            )
          }
          context "value falls within all constraints" do
            it "does not set any violations" do
              input.value = "123456"
              expect(input.valid?).to eq(true)
            end
          end
          context "value's length is the minlength" do
            it "does not set any violations" do
              input.value = "12345"
              expect(input.valid?).to eq(true)
            end
          end
          context "value's length is the maxlength" do
            it "does not set any violations" do
              input.value = "1234567890"
              expect(input.valid?).to eq(true)
            end
          end
          context "value's length is below minlength" do
            it "sets tooShort" do
              input.value = "1234"
              expect(input.validity_state).to have_constraint_violation(:tooShort)
            end
          end
          context "value's length is above maxlength" do
            it "sets tooLong" do
              input.value = "12345678901"
              expect(input.validity_state).to have_constraint_violation(:tooLong)
            end
          end
          context "value's length is fine, but doesn't match pattern" do
            it "sets patternMismatch" do
              input.value = "abcdefgh"
              expect(input.validity_state).to have_constraint_violation(:patternMismatch)
            end
          end
        end
        context "value is blank" do
          context ":required is true" do
            it "sets valueMissing, but not any others" do
              input = described_class.new(
                input_definition: Brut::FrontEnd::Forms::InputDefinition.new(
                  type:,
                  name:,
                  required: true,
                  minlength: 1,
                  maxlength: 2,
                  pattern: "foo",
                ),
                index: 0,
                value: "",
              )
              expect(input.validity_state).to have_constraint_violation(:valueMissing)
              expect(input.validity_state).not_to have_constraint_violation(:tooShort)
              expect(input.validity_state).not_to have_constraint_violation(:patternMismatch)
            end
          end
        end
      end
    end
    context "type=number" do
      context "value is present" do
        context "value is a number" do
          let(:input) {
            described_class.new(
              input_definition: Brut::FrontEnd::Forms::InputDefinition.new(
                type: "number",
                name:,
                min: -10,
                max: 20,
                step: 0.1,
                required: true,
              ),
              index: 0,
              value: "0",
            )
          }
          context "value falls within all constraints" do
            it "does not set any violations" do
              input.value = 0
              expect(input.valid?).to eq(true)
              expect(input.value).to eq("0")
              expect(input.typed_value).to eq(BigDecimal("0"))
            end
          end
          context "value is at minimum" do
            it "does not set any violations" do
              input.value = -10 
              expect(input.valid?).to eq(true)
              expect(input.value).to eq("-10")
              expect(input.typed_value).to eq(BigDecimal("-10"))
            end
          end
          context "value is at maximum" do
            it "does not set any violations" do
              input.value = 20 
              expect(input.valid?).to eq(true)
              expect(input.value).to eq("20")
              expect(input.typed_value).to eq(BigDecimal("20"))
            end
          end
          context "value is below minimum" do
            it "sets rangeUnderflow" do
              input.value = -11
              expect(input.validity_state).to have_constraint_violation(:rangeUnderflow)
              expect(input.value).to eq("-11")
              expect(input.typed_value).to eq(BigDecimal("-11"))
            end
          end
          context "value is above maximum" do
            it "sets rangeOverflow" do
              input.value = 21
              expect(input.validity_state).to have_constraint_violation(:rangeOverflow)
              expect(input.value).to eq("21")
              expect(input.typed_value).to eq(BigDecimal("21"))
            end
          end
          context "value is not a multiple of step" do
            it "sets stepMismatch" do
              input.value = 0.06
              expect(input.validity_state).to have_constraint_violation(:stepMismatch)
              expect(input.value).to eq("0.06")
              expect(input.typed_value).to eq(BigDecimal("0.06"))
            end
          end
        end
        context "value is not a number" do
          it "treats the number as blank" do
            input = described_class.new(
              input_definition: Brut::FrontEnd::Forms::InputDefinition.new(
                type: "number",
                name:,
                min: -10,
                max: 20,
                step: 0.1,
                required: true,
              ),
              index: 0,
              value: "not a number",
            )
            expect(input.validity_state).to have_constraint_violation(:valueMissing)
            expect(input.value).to eq(nil)
            expect(input.typed_value).to eq(nil)
          end
        end
      end
      context "value is blank and required" do
        it "sets valueMissing" do
          input = described_class.new(
            input_definition: Brut::FrontEnd::Forms::InputDefinition.new(
              type: "number",
              name:,
              min: -10,
              max: 20,
              step: 0.1,
              required: true,
            ),
            index: 0,
            value: "",
          )
          expect(input.validity_state).to have_constraint_violation(:valueMissing)
          expect(input.value).to eq(nil)
          expect(input.typed_value).to eq(nil)
        end
      end
    end
    context "type=checkbox" do
      context "value is 'true'" do
        it "has no constraint violations and its typed_value is boolean true" do
          input = described_class.new(
            input_definition: Brut::FrontEnd::Forms::InputDefinition.new(
              type: "checkbox", 
              name:,
            ),
            index: 0,
            value: "true"
          )
          expect(input.valid?).to eq(true)
          expect(input.value).to eq("true")
          expect(input.typed_value).to eq(true)
        end
      end
      context "value is not 'true'" do
        context "it's not required" do
          it "has no constraint violations and its typed_value is boolean false" do
            input = described_class.new(
              input_definition: Brut::FrontEnd::Forms::InputDefinition.new(
                type: "checkbox", 
                name:,
              ),
              index: 0,
              value: "not true"
            )
            expect(input.valid?).to eq(true)
            expect(input.value).to eq("not true")
            expect(input.typed_value).to eq(false)
          end
        end
        context "it is required" do
          it "has valueMissing set and its typed_value is boolean false" do
            input = described_class.new(
              input_definition: Brut::FrontEnd::Forms::InputDefinition.new(
                type: "checkbox", 
                name:,
                required: true,
              ),
              index: 0,
              value: "not true"
            )
            expect(input.validity_state).to have_constraint_violation(:valueMissing)
            expect(input.value).to eq("not true")
            expect(input.typed_value).to eq(false)
          end
        end
      end
    end
    context "type=color" do
      context "value is present" do
        it "does not set any violations" do
          input = described_class.new(
            input_definition: Brut::FrontEnd::Forms::InputDefinition.new(
              type: "color", 
              name:,
              required: true,
            ),
            index: 0,
            value: "#C0FFEE",
          )
          expect(input.valid?).to eq(true)
          expect(input.value).to eq("#C0FFEE")
          expect(input.typed_value).to eq("#c0ffee")
        end
        it "if not a hex code, typed_value is nil" do
          input = described_class.new(
            input_definition: Brut::FrontEnd::Forms::InputDefinition.new(
              type: "color", 
              name:,
            ),
            index: 0,
            value: "#abc"
          )
          expect(input.valid?).to eq(true)
          expect(input.value).to eq(nil)
          expect(input.typed_value).to eq(nil)
        end
      end
    end
    context "type=date" do
      context "value is present" do
        context "value is a date" do
          let(:input) {
            described_class.new(
              input_definition: Brut::FrontEnd::Forms::InputDefinition.new(
                type: "date",
                name:,
                min: "2023-01-01",
                max: "2023-12-31",
                step: 1,
                required: true,
              ),
              index: 0,
              value: "2023-06-15",
            )
          }
          context "value falls within all constraints" do
            it "does not set any violations" do
              input.value = "2023-06-15"
              expect(input.valid?).to eq(true)
              expect(input.value).to eq("2023-06-15")
              expect(input.typed_value).to eq(Date.new(2023, 6, 15))
            end
          end
          context "value is at minimum" do
            it "does not set any violations" do
              input.value = "2023-01-01"
              expect(input.valid?).to eq(true)
              expect(input.value).to eq("2023-01-01")
              expect(input.typed_value).to eq(Date.new(2023, 1, 1))
            end
          end
          context "value is at maximum" do
            it "does not set any violations" do
              input.value = "2023-12-31"
              expect(input.valid?).to eq(true)
              expect(input.value).to eq("2023-12-31")
              expect(input.typed_value).to eq(Date.new(2023, 12, 31))
            end
          end
          context "value is below minimum" do
            it "sets rangeUnderflow" do
              input.value = "2022-12-31"
              expect(input.validity_state).to have_constraint_violation(:rangeUnderflow)
              expect(input.value).to eq("2022-12-31")
              expect(input.typed_value).to eq(Date.new(2022, 12, 31))
            end
          end
          context "value is above maximum" do
            it "sets rangeOverflow" do
              input.value = "2024-01-01"
              expect(input.validity_state).to have_constraint_violation(:rangeOverflow)
              expect(input.value).to eq("2024-01-01")
              expect(input.typed_value).to eq(Date.new(2024, 1, 1))
            end
          end
          context "value is not a multiple of step" do
            it "sets stepMismatch" do
              input = described_class.new(
                input_definition: Brut::FrontEnd::Forms::InputDefinition.new(
                  type: "date",
                  name:,
                  min: "2023-01-01",
                  max: "2023-12-31",
                  step: 10,
                  required: true,
                ),
                index: 0,
                value: "2023-01-03",
              )
              expect(input.validity_state).to have_constraint_violation(:stepMismatch)
              expect(input.value).to eq("2023-01-03")
              expect(input.typed_value).to eq(Date.new(2023, 1, 3))
            end
          end
        end
        context "value is not a date" do
          it "treats the date as blank" do
            input = described_class.new(
              input_definition: Brut::FrontEnd::Forms::InputDefinition.new(
                type: "date",
                name:,
                required: true,
              ),
              index: 0,
              value: "not a date",
            )
            expect(input.validity_state).to have_constraint_violation(:valueMissing)
            expect(input.value).to eq(nil)
            expect(input.typed_value).to eq(nil)
          end
        end
      end
      context "value is blank and required" do
        it "sets valueMissing" do
          input = described_class.new(
            input_definition: Brut::FrontEnd::Forms::InputDefinition.new(
              type: "date",
              name:,
              required: true,
            ),
            index: 0,
            value: "",
          )
          expect(input.validity_state).to have_constraint_violation(:valueMissing)
          expect(input.value).to eq(nil)
          expect(input.typed_value).to eq(nil)
        end
      end
    end
    context "type=datetime-local" do
      context "value is present" do
        context "value is a date" do
          let(:input) {
            described_class.new(
              input_definition: Brut::FrontEnd::Forms::InputDefinition.new(
                type: "datetime-local",
                name:,
                min: "2021-01-03T12:30",
                max: "2022-03-02T14:40",
                step: 10,
                required: true,
              ),
              index: 0,
              value: "2021-05-05T13:22:20",
            )
          }
          context "value falls within all constraints" do
            it "does not set any violations" do
              input.value = "2021-05-05T13:22:20"
              expect(input.valid?).to eq(true)
              expect(input.value).to eq("2021-05-05T13:22:20")
              expect(input.typed_value).to eq(Time.new(2021, 5, 5, 13, 22, 20))
            end
          end
          context "value is at minimum" do
            it "does not set any violations" do
              input.value = "2021-01-03T12:30"
              expect(input.valid?).to eq(true)
              expect(input.value).to eq("2021-01-03T12:30")
              expect(input.typed_value).to eq(Time.new(2021, 1, 3, 12, 30))
            end
          end
          context "value is at maximum" do
            it "does not set any violations" do
              input.value = "2022-03-02T14:40"
              expect(input.valid?).to eq(true)
              expect(input.value).to eq("2022-03-02T14:40")
              expect(input.typed_value).to eq(Time.new(2022, 3, 2, 14, 40))
            end
          end
          context "value is below minimum" do
            it "sets rangeUnderflow" do
              input.value = "2021-01-03T12:29:50"
              expect(input.validity_state).to have_constraint_violation(:rangeUnderflow)
              expect(input.value).to eq("2021-01-03T12:29:50")
              expect(input.typed_value).to eq(Time.new(2021, 1, 3, 12, 29, 50))
            end
          end
          context "value is above maximum" do
            it "sets rangeOverflow" do
              input.value = "2022-03-02T14:40:20"
              expect(input.validity_state).to have_constraint_violation(:rangeOverflow)
              expect(input.value).to eq("2022-03-02T14:40:20")
              expect(input.typed_value).to eq(Time.new(2022, 3, 2, 14, 40, 20))
            end
          end
          context "value is not a multiple of step" do
            it "sets stepMismatch" do
              input.value = "2021-05-05T12:34:03"
              expect(input.validity_state).to have_constraint_violation(:stepMismatch)
              expect(input.value).to eq("2021-05-05T12:34:03")
              expect(input.typed_value).to eq(Time.new(2021, 5, 5, 12, 34, 3))
            end
          end
        end
        context "value is not a datetime-local" do
          it "treats the datetime-local as blank" do
            input = described_class.new(
              input_definition: Brut::FrontEnd::Forms::InputDefinition.new(
                type: "datetime-local",
                name:,
                required: true,
              ),
              index: 0,
              value: "not a datetime-local",
            )
            expect(input.validity_state).to have_constraint_violation(:valueMissing)
            expect(input.value).to eq(nil)
            expect(input.typed_value).to eq(nil)
          end
        end
      end
      context "value is blank and required" do
        it "sets valueMissing" do
          input = described_class.new(
            input_definition: Brut::FrontEnd::Forms::InputDefinition.new(
              type: "datetime-local",
              name:,
              required: true,
            ),
            index: 0,
            value: "",
          )
          expect(input.validity_state).to have_constraint_violation(:valueMissing)
          expect(input.value).to eq(nil)
          expect(input.typed_value).to eq(nil)
        end
      end
    end
    context "type=email" do
      context "value is present" do
        let(:input) {
          described_class.new(
            input_definition: Brut::FrontEnd::Forms::InputDefinition.new(
              type: "email", 
              name:,
              minlength: 5,
              maxlength: 10,
              required: true,
            ),
            index: 0,
            value: "123456",
          )
        }
        context "value falls within all constraints" do
          it "does not set any violations" do
            input.value = "a@a.com"
            expect(input.valid?).to eq(true)
          end
        end
        context "value's length is the minlength" do
          it "does not set any violations" do
            input.value = "a@a.a"
            expect(input.valid?).to eq(true)
          end
        end
        context "value's length is the maxlength" do
          it "does not set any violations" do
            input.value = "a@abcd.com"
            expect(input.valid?).to eq(true)
          end
        end
        context "value's length is below minlength" do
          it "sets tooShort" do
            input.value = "a@a"
            expect(input.validity_state).to have_constraint_violation(:tooShort)
          end
        end
        context "value's length is above maxlength" do
          it "sets tooLong" do
            input.value = "a@very-long-url.com.info"
            expect(input.validity_state).to have_constraint_violation(:tooLong)
          end
        end
        context "value's length is fine, but doesn't match pattern" do
          it "sets patternMismatch" do
            input.value = "abcdefg"
            expect(input.validity_state).to have_constraint_violation(:patternMismatch)
          end
        end
        it "defaults to a stricter pattern than the browser requires" do
          input = described_class.new(
            input_definition: Brut::FrontEnd::Forms::InputDefinition.new(
              type: "email", 
              name:,
            ),
            index: 0,
            value: "browser@allowsthis",
          )
          expect(input.validity_state).to have_constraint_violation(:patternMismatch)
        end
        it "does not override an explicitly-given pattern" do
          input = described_class.new(
            input_definition: Brut::FrontEnd::Forms::InputDefinition.new(
              type: "email", 
              name:,
              pattern: "^[^@]+@example"
            ),
            index: 0,
            value: "foo@example",
          )
          expect(input.valid?).to eq(true)
        end
        it "can not set any pattern if given a special symbol" do
          input = described_class.new(
            input_definition: Brut::FrontEnd::Forms::InputDefinition.new(
              type: "email", 
              name:,
              pattern: nil,
            ),
            index: 0,
            value: "browser@allowsthis",
          )
          expect(input.valid?).to eq(true)
        end
      end
      context "value is blank" do
        context ":required is true" do
          it "sets valueMissing, but not any others" do
            input = described_class.new(
              input_definition: Brut::FrontEnd::Forms::InputDefinition.new(
                type: "email",
                name:,
                required: true,
                minlength: 1,
                maxlength: 2,
                pattern: "foo",
              ),
              index: 0,
              value: "",
            )
            expect(input.validity_state).to have_constraint_violation(:valueMissing)
            expect(input.validity_state).not_to have_constraint_violation(:tooShort)
            expect(input.validity_state).not_to have_constraint_violation(:patternMismatch)
          end
        end
      end
    end
    context "type=file" do
      it "does not set any violations" do
        input = described_class.new(
          input_definition: Brut::FrontEnd::Forms::InputDefinition.new(
            type: "file", 
            name:,
            required: true,
          ),
          index: 0,
          value: ""
        )
        expect(input.valid?).to eq(true)
      end
    end
    context "type=hidden" do
      it "does not set any violations" do
        input = described_class.new(
          input_definition: Brut::FrontEnd::Forms::InputDefinition.new(
            type: "hidden", 
            name:,
            required: true,
          ),
          index: 0,
          value: ""
        )
        expect(input.valid?).to eq(true)
      end
    end
    context "type=radio" do
      context "value is present" do
        it "has no constraint violations" do
          input = described_class.new(
            input_definition: Brut::FrontEnd::Forms::InputDefinition.new(
              type: "radio", 
              name:,
            ),
            index: 0,
            value: "some selection"
          )
          expect(input.valid?).to eq(true)
          expect(input.value).to eq("some selection")
          expect(input.typed_value).to eq("some selection")
        end
      end
      context "value is not set" do
        context "it's not required" do
          it "has no constraint violations" do
            input = described_class.new(
              input_definition: Brut::FrontEnd::Forms::InputDefinition.new(
                type: "radio", 
                name:,
                required: false,
              ),
              index: 0,
              value: ""
            )
            expect(input.valid?).to eq(true)
            expect(input.value).to eq(nil)
            expect(input.typed_value).to eq(nil)
          end
        end
        context "it is required" do
          it "has valueMissing set" do
            input = described_class.new(
              input_definition: Brut::FrontEnd::Forms::InputDefinition.new(
                type: "radio", 
                name:,
                required: true,
              ),
              index: 0,
              value: ""
            )
            expect(input.validity_state).to have_constraint_violation(:valueMissing)
            expect(input.value).to eq(nil)
            expect(input.typed_value).to eq(nil)
          end
        end
      end
    end
    context "type=range" do
      context "value is present" do
        context "value is a number" do
          let(:input) {
            described_class.new(
              input_definition: Brut::FrontEnd::Forms::InputDefinition.new(
                type: "range",
                name:,
                min: -10,
                max: 20,
                step: 0.1,
              ),
              index: 0,
              value: "0",
            )
          }
          context "value falls within all constraints" do
            it "does not set any violations" do
              input.value = 0
              expect(input.valid?).to eq(true)
              expect(input.value).to eq("0")
              expect(input.typed_value).to eq(BigDecimal("0"))
            end
          end
          context "value is at minimum" do
            it "does not set any violations" do
              input.value = -10 
              expect(input.valid?).to eq(true)
              expect(input.value).to eq("-10")
              expect(input.typed_value).to eq(BigDecimal("-10"))
            end
          end
          context "value is at maximum" do
            it "does not set any violations" do
              input.value = 20 
              expect(input.valid?).to eq(true)
              expect(input.value).to eq("20")
              expect(input.typed_value).to eq(BigDecimal("20"))
            end
          end
          context "value is below minimum" do
            it "sets rangeUnderflow" do
              input.value = -11
              expect(input.validity_state).to have_constraint_violation(:rangeUnderflow)
              expect(input.value).to eq("-11")
              expect(input.typed_value).to eq(BigDecimal("-11"))
            end
          end
          context "value is above maximum" do
            it "sets rangeOverflow" do
              input.value = 21
              expect(input.validity_state).to have_constraint_violation(:rangeOverflow)
              expect(input.value).to eq("21")
              expect(input.typed_value).to eq(BigDecimal("21"))
            end
          end
          context "value is not a multiple of step" do
            it "sets stepMismatch" do
              input.value = 0.06
              expect(input.validity_state).to have_constraint_violation(:stepMismatch)
              expect(input.value).to eq("0.06")
              expect(input.typed_value).to eq(BigDecimal("0.06"))
            end
          end
        end
        context "value is not a number" do
          it "treats the number as blank, which is valid, but the browser will choose the value to show by default" do
            input = described_class.new(
              input_definition: Brut::FrontEnd::Forms::InputDefinition.new(
                type: "range",
                name:,
                min: -10,
                max: 20,
                step: 0.1,
              ),
              index: 0,
              value: "not a number",
            )
            expect(input.valid?).to eq(true)
            expect(input.value).to eq(nil)
            expect(input.typed_value).to eq(nil)
          end
        end
      end
      context "value is blank" do
        it "sets valueMissing" do
          input = described_class.new(
            input_definition: Brut::FrontEnd::Forms::InputDefinition.new(
              type: "range",
              name:,
              min: -10,
              max: 20,
              step: 0.1,
            ),
            index: 0,
            value: "",
          )
          expect(input.valid?).to eq(true)
          expect(input.value).to eq(nil)
          expect(input.typed_value).to eq(nil)
        end
      end
    end
    context "type=time" do
      context "value is present" do
        context "value is a date" do
          let(:input) {
            described_class.new(
              input_definition: Brut::FrontEnd::Forms::InputDefinition.new(
                type: "time",
                name:,
                min: "12:34:10",
                max: "16:45:30",
                step: 10,
                required: true,
              ),
              index: 0,
              value: "13:22:20",
            )
          }
          context "value falls within all constraints" do
            it "does not set any violations" do
              input.value = "13:22:20"
              expect(input.valid?).to eq(true)
              expect(input.value).to eq("13:22:20")
              expect(input.typed_value).to eq("13:22:20")
            end
          end
          context "value is at minimum" do
            it "does not set any violations" do
              input.value = "12:34:10"
              expect(input.valid?).to eq(true)
              expect(input.value).to eq("12:34:10")
              expect(input.typed_value).to eq("12:34:10")
            end
          end
          context "value is at maximum" do
            it "does not set any violations" do
              input.value = "16:45:30"
              expect(input.valid?).to eq(true)
              expect(input.value).to eq("16:45:30")
              expect(input.typed_value).to eq("16:45:30")
            end
          end
          context "value is below minimum" do
            it "sets rangeUnderflow" do
              input.value = "12:34:00"
              expect(input.validity_state).to have_constraint_violation(:rangeUnderflow)
              expect(input.value).to eq("12:34:00")
              expect(input.typed_value).to eq("12:34:00")
            end
          end
          context "value is above maximum" do
            it "sets rangeOverflow" do
              input.value = "16:45:40"
              expect(input.validity_state).to have_constraint_violation(:rangeOverflow)
              expect(input.value).to eq("16:45:40")
              expect(input.typed_value).to eq("16:45:40")
            end
          end
          context "value is not a multiple of step" do
            it "sets stepMismatch" do
              input.value = "12:34:03"
              expect(input.validity_state).to have_constraint_violation(:stepMismatch)
              expect(input.value).to eq("12:34:03")
              expect(input.typed_value).to eq("12:34:03")
            end
          end
        end
        context "value is not a time" do
          it "treats the time as blank" do
            input = described_class.new(
              input_definition: Brut::FrontEnd::Forms::InputDefinition.new(
                type: "time",
                name:,
                required: true,
              ),
              index: 0,
              value: "not a time",
            )
            expect(input.validity_state).to have_constraint_violation(:valueMissing)
            expect(input.value).to eq(nil)
            expect(input.typed_value).to eq(nil)
          end
        end
      end
      context "value is blank and required" do
        it "sets valueMissing" do
          input = described_class.new(
            input_definition: Brut::FrontEnd::Forms::InputDefinition.new(
              type: "time",
              name:,
              required: true,
            ),
            index: 0,
            value: "",
          )
          expect(input.validity_state).to have_constraint_violation(:valueMissing)
          expect(input.value).to eq(nil)
          expect(input.typed_value).to eq(nil)
        end
      end
    end
    context "type=url" do
      context "value is present" do
        let(:input) {
          described_class.new(
            input_definition: Brut::FrontEnd::Forms::InputDefinition.new(
              type: "url", 
              name:,
              minlength: 11,
              maxlength: 30,
              required: true,
            ),
            index: 0,
            value: "http://example.com",
          )
        }
        context "value falls within all constraints" do
          it "does not set any violations" do
            input.value = "https://example.net"
            expect(input.valid?).to eq(true)
            expect(input.typed_value.kind_of?(URI)).to eq(true)
          end
        end
        context "value's length is the minlength" do
          it "does not set any violations" do
            input.value = "http://Y.co"
            expect(input.valid?).to eq(true)
            expect(input.typed_value.kind_of?(URI)).to eq(true)
          end
        end
        context "value's length is the maxlength" do
          it "does not set any violations" do
            input.value = "http://example.com/abcdefghijk"
            expect(input.valid?).to eq(true)
            expect(input.typed_value.kind_of?(URI)).to eq(true)
          end
        end
        context "value's length is below minlength" do
          it "sets tooShort" do
            input.value = "ftp://Y.co"
            expect(input.validity_state).to have_constraint_violation(:tooShort)
          end
        end
        context "value's length is above maxlength" do
          it "sets tooLong" do
            input.value = "http://example.com/abcdefghijkL"
            expect(input.validity_state).to have_constraint_violation(:tooLong)
          end
        end
        context "value's length is fine, but doesn't match pattern" do
          it "sets patternMismatch" do
            input = described_class.new(
              input_definition: Brut::FrontEnd::Forms::InputDefinition.new(
                type: "url", 
                name:,
                minlength: 11,
                maxlength: 30,
                required: true,
                pattern: "^https://.*$"
              ),
              index: 0,
              value: "http://example.com",
            )
            expect(input.validity_state).to have_constraint_violation(:patternMismatch)
            expect(input.typed_value.kind_of?(URI)).to eq(true)
          end
        end
        it "by default it sets no pattern, but uses Ruby's URI as a way to check validity" do
          input = described_class.new(
            input_definition: Brut::FrontEnd::Forms::InputDefinition.new(
              type: "url", 
              name:,
              pattern: nil,
            ),
            index: 0,
            value: "xxx/foo.info"
          )
          expect(input.validity_state).to have_constraint_violation(:patternMismatch)
        end
      end
      context "value is blank" do
        context ":required is true" do
          it "sets valueMissing, but not any others" do
            input = described_class.new(
              input_definition: Brut::FrontEnd::Forms::InputDefinition.new(
                type: "url",
                name:,
                minlength: 1,
                maxlength: 2,
                pattern: "foo",
              ),
              index: 0,
              value: "",
            )
            expect(input.validity_state).to have_constraint_violation(:valueMissing)
            expect(input.validity_state).not_to have_constraint_violation(:tooShort)
            expect(input.validity_state).not_to have_constraint_violation(:patternMismatch)
          end
        end
      end
    end
  end
end
