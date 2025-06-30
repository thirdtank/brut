# Mirrors a web browser's ValidityState API, but can also capture additional arbitrary server-side
# constraint violations to create an entire picture of all constraints violated by a given form input.
# In a sense, this is a wrapper for one or more {Brut::FrontEnd::Forms::ConstraintViolation} instances in the
# context of an input.
#
# This class also holds the logic related to client- vs. server-side constraint
# violations.  As such, {.KEYS} is the list of known client-side 
# constraint violation keys, as defined by browser's `ValidityState` class. These
# are left as camel-case to make this clear.
#
# @see https://developer.mozilla.org/en-US/docs/Web/API/ValidityState
class Brut::FrontEnd::Forms::ValidityState
  include Enumerable

  # Create a validity state initialized with the given violations
  #
  # @param [Hash<String,true|false>] constraint_violations map of keys to booleans, where if the boolean is true, there is a
  # constraint violation described by the key.  The keys are i18n fragments used to construct error messages.
  def initialize(constraint_violations={})
    @constraint_violations = constraint_violations.map { |key,is_violation|
      if is_violation
        Brut::FrontEnd::Forms::ConstraintViolation.new(key: key, context: {})
      else
        nil
      end
    }.compact
  end

  # Returns true if there are no constraint violations
  def valid? = @constraint_violations.empty?

  # Returns true if there are constraint violations
  def constraint_violations? = !self.valid?

  # Set a server-side constraint violation. This is essentially arbitrary and dependent
  # on your use-case.
  #
  # @param [String|Symbol] key an I18n key fragment used to create a message about the violation
  # @param [Hash] context interpolated values used to create the message
  def server_side_constraint_violation(key:,context:)
    @constraint_violations << Brut::FrontEnd::Forms::ConstraintViolation.new(key: key, context: context, server_side: true)
  end

  # Iterate over each constraint violation
  #
  # @yield [constraint] called once for each constraint violation
  # @yieldparam constraint [Brut::FrontEnd::Forms::ConstraintViolation]
  def each(&block)
    @constraint_violations.each do |constraint|
      block.call(constraint)
    end
  end


  # These are the attributes of the browser's `ValidityState`'s properties.
  # They are left as camel-case to clearly indicate they come from the browser.
  #
  # @see https://developer.mozilla.org/en-US/docs/Web/API/ValidityState
  KEYS = [
    "badInput",
    "customError",
    "patternMismatch",
    "rangeOverflow",
    "rangeUnderflow",
    "stepMismatch",
    "tooLong",
    "tooShort",
    "typeMismatch",
    "valueMissing",
  ]

end

