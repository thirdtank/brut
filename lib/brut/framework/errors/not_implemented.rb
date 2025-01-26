# Thrown when use of a feature of Brut is detected, but that
# feature is not yet implemented.  This is advisory only and
# not a promise to ever implement that feature.  It's mostly used
# when two APIs are very similar and one might expect both to  
# support the same features, but for technical reasons one of the APIs does not.
class Brut::Framework::Errors::NotImplemented < Brut::Framework::Error
  def initialize(message=nil)
    if message.nil?
      super
    else
      super("NOT IMPLEMENTED: #{message}")
    end
  end
end
