# Raised when a method must be defined by a subclass.  This is useful for making it clear
# which methods a subclass is expected to override and for which no default behavior
# makes sense.
class Brut::Framework::Errors::AbstractMethod < Brut::Framework::Error
  def initialize(method_name=nil)
    if method_name
      super("The method `#{method_name}` must be implemented")
    else
      super("An abstract method must be implemented")
    end
  end
end
