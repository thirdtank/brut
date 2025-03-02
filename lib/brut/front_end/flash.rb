# A hash that can be used to pass short-lived information across requests. Generally, this is useful for storing error and status
# messages.  Generally, you won't create instances of this class. You may subclass it, to provide your own additional API for your
# app's needs. To do that, you must call `Brut.container.override("flash_class",«your class»)`.
class Brut::FrontEnd::Flash

  # Create a flash from a hash of values.
  #
  # @param [Hash] hash the values that should comprise the hash.  Note that this hash is not exactly how the flash stores itself
  # internally.
  def self.from_h(hash)
    hash ||= {}
    self.new(
      age: hash[:age] || 0,
      messages: hash[:messages] || {}
    )
  end

  # Create a new flash of a given age with the given messages initialized
  #
  # @param [Integer] age the age of this flash. See {#age!}.
  # @param [Hash] messages the flash messages to use. Note that `:notice` and `:alert` are special. See {#notice=} and {#alert=}.
  def initialize(age: 0, messages: {})
    @age = age.to_i
    if !messages.kind_of?(Hash)
      raise ArgumentError,"messages must be a Hash, not a #{messages.class}"
    end
    @messages = messages
  end

  # Clear the flash and reset its age to 0.
  def clear!
    @age = 0
    @messages = {}
  end

  # Set the "notice", which is an informational message.  The value is intended to be an I18N key.
  #
  # @param [String|Array] notice the I18n key of the notice. If this is an array, it will be joined with dots to form an I18n key.
  def notice=(notice)
    self[:notice] = if notice
                      Array(notice).map(&:to_s).join(".")
                    else
                      notice
                    end
  end
  # Access the notice. See {#notice=}
  def notice = self[:notice]

  # True if there is a notice
  def notice? = !!self.notice

  # Set the "alert", which is an important error message.  The value is intended to be an I18N key.
  #
  # @param [String|Array] alert the I18n key of the notice.  If this is an array, it will be joined with dots to form an I18n eky.
  def alert=(alert)
    self[:alert] = if alert
                      Array(alert).map(&:to_s).join(".")
                    else
                      alert
                    end
  end
  # Access the alert. See {#alert=}
  def alert = self[:alert]
  # True if there is an alert
  def alert? = !!self.alert

  # Age this flash.  The flash's age is the number of requests in the session it has existed for.  This implementation prevents a
  # flash from being more than 1 request old.  This is usually sufficient for a handler to send information across a redirect.
  def age!
    @age += 1
    if @age > 1
      @age = 0
      @messages = {}
    end
  end

  # Access an arbitrary flash message
  def [](key)
    @messages[key]
  end

  # Set an arbitrary flash message. This resets the flash's age by one request.
  def []=(key,message)
    @messages[key] = message
    @age = [0,@age-1].max
  end

  # Conver this flash into a hash, suitable for passing to {.from_h}
  def to_h
    {
      age: @age,
      messages: @messages,
    }
  end
end
