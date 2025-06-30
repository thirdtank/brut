RSpec::Matchers.define :have_constraint_violation do |field,key:,index:nil|
  match do |form|
    Brut::SpecSupport::Matchers::HaveConstraintViolation.new(form,field,key,index).matches?
  end

  failure_message do |form|
    analysis = Brut::SpecSupport::Matchers::HaveConstraintViolation.new(form,field,key,index)
    if analysis.found_field?
      "Field '#{field}' did not have key '#{key}' as a violation.  These keys were found: #{analysis.keys_on_field_found.map(&:to_s).join(", ")}"
    else
      field_searched_for = if index.nil?
                             field
                           else
                             "#{field}, index #{index}"
                           end
      fields_with_errors = analysis.fields_found.map { |(field,index)|
        if index.nil?
          field
        else
          "#{field}, index #{index}"
        end
      }.join(", ")
      "Field '#{field_searched_for}' had no errors.  These fields DID: #{fields_with_errors}"
    end
  end

  failure_message_when_negated do |form|
    "Found #{key} as a violation on #{field}"
  end
end

# Matcher to check that a from has a specific constraint violation.
#
# @example
#    expect(form).to have_constraint_violation(:email, key: :required)
#
# @example Index fields (requires that the third email field have a constraint violation)
#    expect(form).to have_constraint_violation(:email, key: :required, index: 2)
#
# @example Negated
#    expect(form).not_to have_constraint_violation(:email, key: :required)
class Brut::SpecSupport::Matchers::HaveConstraintViolation
  attr_reader :fields_found
  attr_reader :keys_on_field_found

  def initialize(form, field, key, index)
    if !form.kind_of?(Brut::FrontEnd::Form)
      raise "#{self.class} only works with forms, not #{form.class}"
    end
    @form  = form
    @field = field.to_s
    @key   = key.to_s
    @index = index || 0

    @matches             = false
    @found_field         = false
    @fields_found        = Set.new
    @keys_on_field_found = Set.new

    @form.constraint_violations.each do |input_name, (constraint_violations, index)|
      if input_name.to_s == @field && index == @index
        @found_field = true
        constraint_violations.each do |constraint_violation|
          if constraint_violation.key.to_s == @key
            @matches = true
          else
            @keys_on_field_found << constraint_violation.key.to_s
          end
        end
      else
        @fields_found << [ input_name.to_s, index ]
      end
    end
  end

  def matches?      = @matches
  def found_field?  = @found_field

end
