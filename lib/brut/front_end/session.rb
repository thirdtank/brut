# A class that represents the current session, as opposed to just a Hash.
# Generally, this can act like a Hash for setting and accessing values stored in the session.
# It provides a few useful additions:
#
# * Your app can extend this to provide an app-specific API around the session, using `Brut.container.override("session_class",«your class»)`.
# * There is direct access to commonly-used data stored in the session, such as the flash.
class Brut::FrontEnd::Session
  # Create the session based on the session provided by Rack.
  #
  # @param [Rack session] rack_session the session as provided by Rack. This is treated as a Hash.
  def initialize(rack_session:)
    @rack_session = rack_session
  end

  # Return the interpretation of the `Accept-Language` header that was set by (#http_accept_language=).
  #
  # @return [Brut::I18n::HTTPAcceptLanguage] Never returns `nil`. If the value is corrupted or invalid, an instance that uses English
  # will be returned.
  def http_accept_language = Brut::I18n::HTTPAcceptLanguage.from_session(self[:__brut_http_accept_language])

  # Set the `Accept-Language` for the session, as an {Brut::I18n::HTTPAcceptLanguage}
  # @param [Brut::I18n::HTTPAcceptLanguage] http_accept_language
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

  # Access the underlying session directly
  #
  # @param [Symbol|String] key the key to use. Coerced into a string.
  # @return [Object] whatever value, including `nil`, is in the session for this key.
  def[](key) = @rack_session[key.to_s]

  # Set the session value for the key.
  #
  # @param [Symbol|String] key the key to use. Coerced into a string.
  # @param [Object] value Value to use. Note that this value may be coerced into a string in a way that may not work for your use case.
  # You are encouraged to send in a string. If you want to store rich data in the session, maybe don't? But if you must, add a
  # method to do the marshalling in your app's subclass of this
  def[]=(key,value)
    @rack_session[key.to_s] = value
  end

  # Delete a key from the session. This is preferred to setting the value to `nil`
  def delete(key) = @rack_session.delete(key.to_s)

  # Access the flash, as an instance of whatever class has been configured. Note that this returns a copy of the flash, so any changes
  # will not be stored in the session unless you call (#flash=) after changing it.  Generally, this isn't a big deal as Brut handles
  # this for you.
  def flash
    Brut.container.flash_class.from_h(self[:__brut_flash])
  end
  # Set the flash.
  def flash=(new_flash)
    self[:__brut_flash] = new_flash.to_h
  end
end
