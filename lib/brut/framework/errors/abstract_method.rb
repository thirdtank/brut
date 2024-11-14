class Brut::Framework::Errors::AbstractMethod < Brut::Framework::Error
  def initialize(message=nil)
    if message.nil?
      super
    else
      super("Subclass must implement: #{message}")
    end
  end
end
