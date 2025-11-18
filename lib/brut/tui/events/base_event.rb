require "brut/junk_drawer"

# Base class for all events the TUI will manage.  You can create custom
# events but they must subclass this one (or conform to its interface, which may change).
class Brut::TUI::Events::BaseEvent
  # Returns the method name that subscribers must implement to handle this event.
  # By default, this is based on the underscorized simple class name (name without module namespacing)
  # suffixed with `on_`.
  def self.handler_method_name 
    @handler_method_name ||= begin
                               simple_class_name = RichString.new(self.name.split("::").last)
                               "on_#{simple_class_name.underscorized}"
                             end
  end

  # Provides `class_name` and `handler_method_name`. Subclasses are expected to call this
  # so they are included with their keys.
  def deconstruct_keys(keys=nil)
    { class_name: self.class.name, handler_method_name: self.class.handler_method_name }
  end

  # True if the reception of this event indicates the app should exit right now, potentially
  # leaving un-handled events.
  def exit? = false

  # True if this event indicates the TUI should exit, but draining any
  # outstanding events is OK first.
  def drain_then_exit? = false
end
