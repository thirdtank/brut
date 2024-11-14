# Thrown when a codepath should never have been allowed
# to occur.  This is useful is signaling that the system
# has some sort of bug in its integration. For example,
# attempting to perform an action that the UI should've
# prevented
class Brut::Framework::Errors::Bug < Brut::Framework::Error
  def initialize(message=nil)
    if message.nil?
      super
    else
      super("BUG: #{message}")
    end
  end
end
