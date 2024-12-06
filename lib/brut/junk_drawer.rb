require "tzinfo"
# Models a clock, which is a time in the context of a time zone.  This theoretically makes it easier to get the time and date at the time zone of the user.
class Clock
  # Create a clock in the given timezone.  If `tzinfo_timezone` is non-`nil`, that value is the time zone of the clock, and all `Time`
  # instances returned will be in that time zone.  If `tzinfo_timezone` is `nil`, then `ENV["TZ"]` is consulted. If the value of that
  # environment variable is a valid timezone, it is used. Otherwise, UTC is used.
  #
  # @param [TZInfo::Timezone] tzinfo_timezone if present, this is the timezone of the clock.
  def initialize(tzinfo_timezone)
    if tzinfo_timezone
      @timezone = tzinfo_timezone
    elsif ENV["TZ"]
      @timezone = begin
                    TZInfo::Timezone.get(ENV["TZ"])
                  rescue TZInfo::InvalidTimezoneIdentifier => ex
                    SemanticLogger[self.class.name].warn("#{ex} from ENV['TZ'] value '#{ENV['TZ']}'")
                    nil
                  end
    end
    if @timezone.nil?
      @timezone = TZInfo::Timezone.get("UTC")
    end
  end

  # Get the current time in the configured timezone
  def now
    Time.now(in: @timezone)
  end

  # Convert the given time to this clock's time zone
  def in_time_zone(time)
    @timezone.to_local(time)
  end
end

# A wrapper around a string to avoid adding a ton of methods to `String`.
class RichString
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
      part.capitalize
    }.join("")
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

