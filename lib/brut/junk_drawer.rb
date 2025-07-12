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
  #               now.  Don't do this unless you are testing.
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
#
# This may not survive to 1.0 - use at your own risk.
class RichString
  # Create a RichString, return `nil` instead for blank strings or nil
  # @param [String|nil] string the string to convert.
  # @param [true|false] blank_is_nil if true, a blank string or nil is considered
  #        nil and nil is returned.
  # @return [RichString|nil] a RichString containing the string or nil if the 
  #         string is blank or nil, accounting for `blank_is_nil:`
  def self.from_string(string,blank_is_nil:true)
    if string.nil?
        return nil
    end
    if string.to_s.strip == "" && blank_is_nil
      return nil
    end
    self.new(string)
  end

  # Create a RichString. This calls `to_s` on its argument.
  #
  # @param [String|Object] string the string to wrap. `to_s` is called, so be sure
  #        that's what you want.
  def initialize(string)
    @string = string.to_s
  end

  # Return a snake_case version of the string.  This will convert dashes to
  # underscores, and use A-Z to know where to insert underscores.  Repeated
  # underscores are coalesced into one, and there will be no leading or trailing
  # underscores in the string.
  # @visibility private
  def underscorized
    RichString.new(
      self.to_s.split(/([A-Z])/).
      select { it.length > 0 }.
      map { |part|
        if part == part.upcase
          "_#{part.downcase}"
        else
          part
        end
      }.
      join.gsub("-","_").
      gsub(/[_]+/,"_").
      gsub(/^_+/,"").
      gsub(/_+$/,"")
    )
  end

  # Turn a string into CamelCase by captializing any
  # letter that is preceded by an underscore or dash.
  # @visibility private
  def camelize
    @string.to_s.split(/[_-]/).select {
      it.strip.length > 0
    }.map {
      RichString.new(it).capitalize(:first_only).to_s
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
  # @visibility private
  def capitalize(*options)
    if options.include?(:first_only)
      options.delete(:first_only)
      self.class.new(@string[0].capitalize(*options) + @string[1..-1])
    else
      self.class.new(@string.capitalize(*options))
    end
  end

  # Takes a snake_case_or-kebab-case-string and returns it with the underscores
  # and dashes replaced with spaces.
  # @visibility private
  def humanized
    RichString.new(@string.tr("_-"," "))
  end

  def to_s = @string
  def to_str = self.to_s
  def length = to_s.length

  def to_s_or_nil = @string.to_s.strip.empty? ? nil : self.to_s

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

class ModuleName
  def self.from_string(string)
    string = RichString.from_string(string)
    if string.nil?
      raise ArgumentError, "ClassName cannot be initialized with a blank string"
    end
    self.new(string.camelize.split(/::/).map { RichString.new(it) })
  end

  attr_reader :parts_of_module

  def initialize(parts_of_module)
    @parts_of_module = parts_of_module
  end

  def in_module(module_name)
    if in_module?(module_name)
      return self
    else
      module_name.append(self)
    end
  end

  def append(module_name)
    self.class.new(@parts_of_module + module_name.parts_of_module)
  end

  def to_s = @parts_of_module.join("::")

  def path_from(base_path, extname: ".rb")
    parts_as_path_segment = @parts_of_module.map { |part|
      if part.to_s == "DB"
        "db"
      else
        part.underscorized.to_s
      end
    }
    *subdir_parts,file_name_part = parts_as_path_segment
    base_path.join(*subdir_parts,file_name_part + extname)
  end

private

  def in_module?(module_name)
    if module_name.parts_of_module.length <= @parts_of_module.length
      module_name.parts_of_module == @parts_of_module[0, module_name.parts_of_module.length]
    else
      false
    end
  end

end

