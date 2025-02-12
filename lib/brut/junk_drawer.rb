require "tzinfo"
# Models a clock, which is a time in the context of a time zone.  This theoretically makes it easier to get the time and date at the time zone of the user.
class Clock
  attr_reader :timezone
  # Create a clock in the given timezone.  If `tzinfo_timezone` is non-`nil`, that value is the time zone of the clock, and all `Time`
  # instances returned will be in that time zone.  If `tzinfo_timezone` is `nil`, then `ENV["TZ"]` is consulted. If the value of that
  # environment variable is a valid timezone, it is used. Otherwise, UTC is used.
  #
  # @param [TZInfo::Timezone] tzinfo_timezone if present, this is the timezone of the clock.
  # @param [Time] now if omitted, uses `Time.now` when asked the current time. Otherwises, uses this value, as a `Time` for
  # now.  Don't do this unless you are testing.
  def initialize(tzinfo_timezone, now: nil)
    if tzinfo_timezone
      @timezone = tzinfo_timezone
    elsif ENV["TZ"]
      @timezone = begin
                    TZInfo::Timezone.get(ENV["TZ"])
                  rescue TZInfo::InvalidTimezoneIdentifier => ex
                    Brut.container.instrumentation.record_exception(ex, class: self.class, invalid_env_tz: ENV['TZ'])
                    nil
                  end
    end
    if @timezone.nil?
      @timezone = TZInfo::Timezone.get("UTC")
    end
    @now = now
  end

  # Get the current time in the configured timezone, unless `now:` was used in the constructor, in which case *that* timestamp is
  # returned in the configured time zone.
  #
  # @return [Time] the time now in the time zone of this clock
  def now
    if @now
      self.in_time_zone(@now)
    else
      Time.now(in: @timezone)
    end
  end

  def today
    self.now.to_date
  end

  # Convert the given time to this clock's time zone
  # @param [Time] time a timestamp you wish to conver to this clock's time zone
  # @return [Time] a new `Time` in the timezone of this clock.
  def in_time_zone(time)
    @timezone.to_local(time)
  end
end

# A wrapper around a string to avoid adding a ton of methods to `String`.
class RichString
  def self.from_string(string,blank_is_nil:true)
    if string.to_s.strip == "" && blank_is_nil
      return nil
    end
    self.new(string)
  end
  def initialize(string)
    @string = string.to_s
  end

  def underscorized
    return self unless /[A-Z-]|::/.match?(@string)
    word = @string.gsub("::", "/")
    word.gsub!(/(?<=[A-Z])(?=[A-Z][a-z])|(?<=[a-z\d])(?=[A-Z])/, "_")
    word.tr!("-", "_")
    word.downcase!
    RichString.new(word)
  end

  def camelize
    @string.to_s.split(/[_-]/).map { |part|
      RichString.new(part).capitalize(:first_only).to_s
    }.join("")
  end

  # Capitalizes the string, with the ability to only capitalize the first letter.
  #
  # If `options` includes `:first_only`, then only the first letter of the string is capitalized. The remaining letters are left
  # alone.  If `option` does not include `:first_only`, this capitalizes like Ruby's standard library, which is to lower case all
  # letters save for the first.
  #
  # @param [Array] options options suitable for Ruby's built-in `String#capitalize` method
  # @return [RichString] a new string where the wrapped string has been capitalized
  def capitalize(*options)
    if options.include?(:first_only)
      options.delete(:first_only)
      self.class.new(@string[0].capitalize(*options) + @string[1..-1])
    else
      self.class.new(@string.capitalize(*options))
    end
  end

  def humanized
    RichString.new(@string.tr("_-"," "))
  end

  def to_s = @string
  def to_str = self.to_s
  def length = to_s.length

  def to_s_or_nil = @string.empty? ? nil : self.to_s

  def ==(other)
    if other.kind_of?(RichString)
      self.to_s == other.to_s
    elsif other.kind_of?(String)
      self.to_s == other
    else
      false
    end
  end

  def <=>(other)
    if other.kind_of?(RichString)
      self.to_s <=> other.to_s
    elsif other.kind_of?(String)
      self.to_s <=> other
    else
      super
    end
  end

  def +(other)
    if other.kind_of?(RichString)
      RichString.new(self.to_s + other.to_s)
    elsif other.kind_of?(String)
      self.to_s + other
    else
      super(other)
    end
  end

end

