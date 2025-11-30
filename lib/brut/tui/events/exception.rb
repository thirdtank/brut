# Fired when an exception is caught. In general, your code should endeavor
# to catch exceptions, wrap them in this, and fir it.
#
# You can control if the app should exit by setting `fatal: true` when
# creating the event. Note that by default, all exceptions are treated
# as fatal, since you generally don't want to use them for control flow.
class Brut::TUI::Events::Exception < Brut::TUI::Events::BaseEvent
  attr_reader :exception
  def initialize(exception)
    @exception = exception
  end

  # Returns true if this event is not considered fatal.
  def drain_then_exit? = !exit?

  # By default, all exceptions should cause an immediate exit.  You may subclass this event to do
  # something different, noting that `#drain_then_exit?` returns true if this returns false.
  def exit?            =  true

  # Includes `exception`, which is the exception that triggered this event.
  def deconstruct_keys(keys=nil)
    super.merge({ exception: @exception})
  end
end
