class Brut::FrontEnd::Flash
  def self.from_h(hash)
    hash ||= {}
    self.new(
      age: hash[:age] || 0,
      messages: hash[:messages] || {}
    )
  end
  def initialize(age: 0, messages: {})
    @age = age.to_i
    if !messages.kind_of?(Hash)
      raise ArgumentError,"messages must be a Hash, not a #{messages.class}"
    end
    @messages = messages
  end

  def clear!
    @age = 0
    @messages = {}
  end

  def notice=(notice)
    self[:notice] = notice
  end
  def notice = self[:notice]
  def notice? = !!self.notice

  def alert=(alert)
    self[:alert] = alert
  end
  def alert = self[:alert]
  def alert? = !!self.alert

  def age!
    @age += 1
    if @age > 1
      @age = 0
      @messages = {}
    end
  end

  def [](key)
    @messages[key]
  end

  def []=(key,message)
    @messages[key] = message
    @age = [0,@age-1].max
  end

  def to_h
    {
      age: @age,
      messages: @messages,
    }
  end
end
