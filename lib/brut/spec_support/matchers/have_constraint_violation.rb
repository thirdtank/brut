RSpec::Matchers.define :have_constraint_violation do |field,key:|
  match do |form|
    Brut::SpecSupport::Matchers::HaveConstraintViolation.new(form,field,key).matches?
  end

  failure_message do |form|
    analysis = Brut::SpecSupport::Matchers::HaveConstraintViolation.new(form,field,key)
    if analysis.found_field?
      "Field '#{field}' did not have key '#{key}' as a violation.  These keys were found: #{analysis.keys_on_field_found.map(&:to_s).join(", ")}"
    else
      "Field '#{field}' had no errors.  These fields DID: #{analysis.fields_found.map(&:to_s).join(", ")}"
    end
  end

  failure_message_when_negated do |form|
    "Found #{key} as a violation on #{field}"
  end
end

class Brut::SpecSupport::Matchers::HaveConstraintViolation
  attr_reader :fields_found
  attr_reader :keys_on_field_found

  def initialize(form, field, key)
    if !form.kind_of?(Brut::FrontEnd::Form)
      raise "#{self.class} only works with forms, not #{form.class}"
    end
    @form  = form
    @field = field.to_s
    @key   = key.to_s

    @matches             = false
    @found_field         = false
    @fields_found        = Set.new
    @keys_on_field_found = Set.new

    @form.constraint_violations.each do |input_name, constraint_violations|
      if input_name.to_s == @field
        @found_field = true
        constraint_violations.each do |constraint_violation|
          if constraint_violation.key.to_s == @key
            @matches = true
          else
            @keys_on_field_found << constraint_violation.key.to_s
          end
        end
      else
        @fields_found << input_name.to_s
      end
    end
  end

  def matches?      = @matches
  def found_field?  = @found_field

end
