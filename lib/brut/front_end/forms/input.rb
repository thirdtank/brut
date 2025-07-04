require "uri"

# An Input is a stateful object representing a specific input and its value
# during the course of a form submission process. In particular, it wraps a value
# and a {Brut::FrontEnd::Forms::ValidityState}. These are mutable, whereas
# the wrapped {Brut::FrontEnd::Forms::InputDefinition} is not.
#
# Of note, this class also initiates the server-execution of the
# client-side validations.  When a form is posted, and you ask the form 
# to validate itself, this class examines the value for the inputs
# and determines if a client-side violation should've happened in the browser.
#
# It does its best to mimic the browser's behavior, however there will be
# some subtle differences.
#
# An important considering is that everything is a string.  The browser wants
# strings and its internal API is string-based.  So is this.  That said, 
# this will convert strings into richer types in order to perform constraint
# analysis.
#
# Where possible, standard library classes are used, but in some cases - 
# colors and times - there is no standard library class.
#
# See {#typed_value}.
class Brut::FrontEnd::Forms::Input

  extend Forwardable

  # @return [String] the input's value. **DO NOTE** this returns a string.  This is
  #         because HTML stores these values as Strings.  When using a checkbox, in
  #         particular, the value will *not* be a boolean. You cannot do `if
  #         input.value` and expect that work. See {#typed_value} instead.
  attr_reader :value

  # @return [Date|Time|BigDecimal|String|true|false|nil] the value of the input,
  #         as coerced to the type used to evaluate constraints.
  #         Returns `nil` if the value could not be coerced (which likely means
  #         there is or will be a constraint violation), **or**
  #         if it is a blank String.
  #
  #         Of note, `type=color` will return a String here, but that String
  #         should be parseable into a hex code, i.e. #XXXXXX, where each "X"
  #         is 0-9 or a-f.  Further, `type=time` will also return a string
  #         in the format HH:MM or HH:MM:SS, where the time is in 24 hour
  #         time.  Lastly, `type=datetime-local` will return a `Time`, even
  #         though the control allows the visitor to choose an invalid time.
  #         If there is no `valueMissing` constraint violation, but this
  #         attribute returns `nil`, {#value} *will* return the string sent by 
  #         the browser, even if it's not a real timestamp.
  attr_reader :typed_value

  # @return [Brut::FrontEnd::Forms::ValidityState] Validity state that captures the current constraint violations, if any
  attr_reader :validity_state

  # Create the input with the given definition and value
  # @param [Brut::FrontEnd::Forms::InputDefinition] input_definition
  # @param [String] value
  def initialize(input_definition:, value:, index:)
    @input_definition = input_definition
    @validity_state = Brut::FrontEnd::Forms::ValidityState.new
    @index = index
    self.value=(value)
  end

  # @!method max
  # @return [String|nil] the value from the `input_definition` given to the
  #         initializer

  # @!method maxlength
  # @return [String|nil] the value from the `input_definition` given to the
  #         initializer

  # @!method min
  # @return [String|nil] the value from the `input_definition` given to the
  #         initializer

  # @!method minlength
  # @return [String|nil] the value from the `input_definition` given to the
  #         initializer

  # @!method name
  # @return [String|nil] the value from the `input_definition` given to the
  #         initializer

  # @!method pattern
  # @return [String|nil] the value from the `input_definition` given to the
  #         initializer

  # @!method required
  # @return [String|nil] the value from the `input_definition` given to the
  #         initializer

  # @!method step
  # @return [String|nil] the value from the `input_definition` given to the
  #         initializer

  # @!method type
  # @return [String|nil] the value from the `input_definition` given to the
  #         initializer

  # @!method array?
  # @return [String|nil] the value from the `input_definition` given to the
  #         initializer

  def_delegators :"@input_definition", :max,
                                       :maxlength,
                                       :min,
                                       :minlength,
                                       :name,
                                       :pattern,
                                       :required,
                                       :step,
                                       :type,
                                       :array?

  # Set the value, analyzing it for constraint violations based on the input's definition.
  # This is essentially duplicating whatever the browser would be doing on its end, thus allowing
  # for server-side validation of client-side constraints.
  #
  # When this method completes, the value of {#validity_state} could change.
  #
  # @param [String] new_value the value for the input. Any non-String value will
  #                 be coerced to a String via `to_s`.
  def value=(new_value)
    new_value = new_value.to_s
    @typed_value = case self.type
                  when "number"
                    BigDecimal(new_value, exception: false)
                  when "range"
                    BigDecimal(new_value, exception: false)
                  when "checkbox"
                    new_value == "true"
                  when "color"
                    Color.from_hex_string(new_value)&.to_s
                  when "date"
                    begin
                      Date.parse(new_value)
                    rescue
                      nil
                    end
                  when "time"
                    TimeOfDay.from_string(new_value)
                  when "datetime-local"
                    begin
                      Time.parse(new_value)
                    rescue
                      nil
                    end
                  when "url"
                    begin
                      URI(new_value)
                    rescue
                      nil
                    end
                  else
                    new_value.strip == "" ? nil : new_value
                  end

    if type == "hidden" || type == "file"
      @value = new_value
      return
    end

    value_missing = new_value.strip == "" || @typed_value.nil?

    missing = if self.required
                value_missing || @typed_value == false
              else
                false
              end
    too_short = if self.minlength && !value_missing
                  new_value.length < self.minlength
                else
                  false
                end

    too_long = if self.maxlength && !value_missing
                 new_value.length > self.maxlength
               else
                 false
               end

    range_overflow = if self.max && !value_missing
                       if type == "date"
                         max_date = Date.parse(self.max)
                         @typed_value > max_date
                       elsif type == "datetime-local"
                         max_date = Time.parse(self.max)
                         @typed_value > max_date
                       elsif type == "time"
                         max_time = TimeOfDay.from_string(self.max)
                         @typed_value > max_time
                       else
                         new_value.to_i > self.max
                       end
                     else
                       false
                     end

    range_underflow = if self.min && !value_missing
                        if type == "date"
                          min_date = Date.parse(self.min)
                          @typed_value < min_date
                        elsif type == "datetime-local"
                          min_date = Time.parse(self.min)
                          @typed_value < min_date
                        elsif type == "time"
                          min_time = TimeOfDay.from_string(self.min)
                          @typed_value < min_time
                        else
                          new_value.to_i < self.min
                        end
                     else
                       false
                     end

    pattern_mismatch = if self.pattern && !value_missing
                         !new_value.match?(Regexp.new(self.pattern))
                       elsif type == "url" && !value_missing
                         @typed_value.nil? || !@typed_value.absolute
                       end
    step_mismatch = if self.step && !value_missing
                      step_big_decimal = BigDecimal(self.step.to_s)
                      if type == "date"
                        basis_date = self.min ? Date.parse(self.min) : Date.parse("1970-01-01")
                        num_days = (@typed_value - basis_date)
                        num_days % step_big_decimal != 0
                      elsif type == "datetime-local"
                        basis_time = self.min ? Time.parse(self.min) : Time.parse("1970-01-01T00:00:00")
                        num_seconds = (@typed_value - basis_time)
                        num_seconds % step_big_decimal != 0
                      elsif type == "time"
                        basis_time = self.min ? TimeOfDay.from_string(self.min) : TimeOfDay.new(hour: 0, minute: 0, second: 0)
                        num_seconds = (@typed_value - basis_time)
                        num_seconds % step_big_decimal != 0
                      else
                        @typed_value % step_big_decimal != 0
                      end
                    end

    if type == "range" || type == "color"
      missing = false
    elsif type == "time"
      @typed_value = @typed_value&.to_s
    end

    @validity_state = Brut::FrontEnd::Forms::ValidityState.new(
      valueMissing: missing,
      tooShort: too_short,
      tooLong: too_long,
      rangeOverflow: range_overflow,
      rangeUnderflow: range_underflow,
      patternMismatch: pattern_mismatch,
      stepMismatch: step_mismatch,
      typeMismatch: false,
    )
    @value = value_missing ? nil : new_value
  end

  # Set a server-side constraint violation on this input.  This is essentially arbitrary, but note
  # that `key` should not be a key used for client-side validations.
  #
  # @param [String|Symbol] key the I18n key fragment that describes the server side constraint violation
  # @param [Hash|nil] context any interpolations required to render the message
  def server_side_constraint_violation(key,context=true)
    @validity_state.server_side_constraint_violation(key: key, context: context)
  end

  # @return [true|false] true if the underlying {#validity_state} has no constraint violations
  def valid? = @validity_state.valid?

  class Color
    def self.from_hex_string(string)
      string = string.to_s
      if string.match?(/\A#[0-9a-fA-F]{6}\z/)
        string.downcase
      else
        nil
      end
    end
  end

  class TimeOfDay
    include Comparable
    def self.from_string(string)
      match_data = string.match(/\A([01]?[0-9]|2[0-3]):([0-5][0-9])(:([0-5][0-9]))?\z/)
      if match_data
        hour = match_data[1].to_i
        minute = match_data[2].to_i
        second = match_data[4] ? match_data[4].to_i : nil
        self.new(hour:, minute:, second:)
      else
        nil
      end
    end

    def initialize(hour:, minute:, second:)
      @hour   = in_range!(hour,   0, 23, "hour")
      @minute = in_range!(minute, 0, 59, "minute")
      @second = second.nil? ? nil : in_range!(second, 0, 59, "second")
    end

    def to_s
      if @second.nil?
        sprintf("%02d:%02d", @hour, @minute)
      else
        sprintf("%02d:%02d:%02d", @hour, @minute, @second)
      end
    end

    def to_seconds
      (@second ||    0) + 
      (@minute  *   60) + 
      (@hour    * 3600)
    end

    def -(other)
      if other.kind_of?(self.class)
        self.to_seconds - other.to_seconds
      else
        raise ArgumentError, "Cannot subtract #{other.class} from TimeOfDay"
      end
    end

    def <=>(other)
      return -1 if !other.kind_of?(self.class)
      self.to_seconds <=> other.to_seconds
    end

  private

    def in_range!(value, min, max, name)
      if value < min || value > max
        raise ArgumentError, "Invalid #{name} '#{value}' (must be between #{min} and #{max})"
      end
      value
    rescue ArgumentError => e
      raise ArgumentError, "Invalid TimeOfDay: #{e.message}"
    end
  end
end
