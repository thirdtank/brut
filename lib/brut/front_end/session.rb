# A class that represents the current session, as opposed to just a Hash.
# Generally, this can act like a Hash for setting and accessing values stored in the session.
# It provides a few useful additions:
#
# * Your app can extend this to provide an app-specific API around the session.
# * There is direct access to commonly-used data stored in the session, such as the flash.
class Brut::FrontEnd::Session
  def initialize(rack_session:)
    @rack_session = rack_session
  end

  def http_accept_language = Brut::I18n::HTTPAcceptLanguage.from_session(self[:__brut_http_accept_language])
  def http_accept_language=(http_accept_language)
    self[:__brut_http_accept_language] = http_accept_language.for_session
  end

  # Get the timezone as reported by the browser, or nil if there isn't one or the browser sent and invalid value
  #
  # @return [TZInfo::Timezone|nil]
  def timezone_from_browser
    tz_name = self[:__brut_timezone_from_browser]
    if tz_name.nil?
      return nil
    end
    begin
      TZInfo::Timezone.get(tz_name)
    rescue TZInfo::InvalidTimezoneIdentifier => ex
      SemanticLogger[self.class.name].warn(ex)
      nil
    end
  end

  # Set the timezone as reported by the browser.
  #
  # @param timezone [TZInfo::Timezone|String] The timezone, or name of a timezone suitable for use with `TZInfo::Timezone`.
  def timezone_from_browser=(timezone)
    if timezone.kind_of?(TZInfo::Timezone)
      timezone = timezone.name
    end
    self[:__brut_timezone_from_browser] = timezone
  end

  # Set the session timezone, regardless of what the browser reports.
  #
  # @param timezone [TZInfo::Timezone|String|nil] The timezone, or name of a timezone suitable for use with `TZInfo::Timezone`. Use
  # `nil` to clear this value and use the browser's time zone.
  def timezone=(timezone)
    if timezone.kind_of?(TZInfo::Timezone)
      timezone = timezone.name
    end
    self[:__brut_timezone_override] = timezone
  end

  # Get the session timezone. This is the preferred way to get a timezone for the current session.  Always returns a value, based on
  # the following logic:
  #
  # 1. If {#timezone=} has been called with a value, that time zone is returned.
  # 2. If {#timezone=} has been given no value or `nil`, and {#timezone_from_browser} returns a value, that value is used.
  # 3. If {#timezone_from_browser} returns `nil`, `ENV["TZ"]` is used, assuming it is a valid time zone.
  # 4. If 'ENV["TZ"]` is blank or invalid, UTC is returned.
  #
  # It is in your best interest to ensure that each session has a valid time zone.
  #
  # @return [TZInfo::Timezone]
  def timezone
    tz_name = self[:__brut_timezone_override]
    timezone = nil
    if !tz_name.nil?
      begin
        timezone = TZInfo::Timezone.get(tz_name)
      rescue TZInfo::InvalidTimezoneIdentifier => ex
        SemanticLogger[self.class.name].warn("Somehow, an invalid time zone was stored in the __brut_timezone_override: '#{tz_name}' (#{ex}")
      end
    end
    if timezone.nil?
      timezone = self.timezone_from_browser
    end
    if timezone.nil?
      begin
        timezone = TZInfo::Timezone.get(ENV["TZ"])
      rescue TZInfo::InvalidTimezoneIdentifier => ex
        SemanticLogger[self.class.name].warn("Somehow, an invalid time zone was stored in the ENV['TZ']: '#{ENV['TZ']}' (#{ex}")
        nil
      end
    end
    if timezone.nil?
      timezone = TZInfo::Timezone.get("UTC")
    end
    timezone
  end

  def[](key) = @rack_session[key.to_s]

  def[]=(key,value)
    @rack_session[key.to_s] = value
  end

  def delete(key) = @rack_session.delete(key.to_s)

  # Access the flash, as an instance of whatever class has been configured.
  def flash
    Brut.container.flash_class.from_h(self[:__brut_flash])
  end
  def flash=(new_flash)
    self[:__brut_flash] = new_flash.to_h
  end
end
