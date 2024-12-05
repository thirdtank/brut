# Raised when a method must be defined by a subclass.  This is useful for making it clear
# which methods a subclass is expected to override and for which no default behavior
# makes sense.
class Brut::Framework::Errors::AbstractMethod < Brut::Framework::Error
end
