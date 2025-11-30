# An event loop used to power any TUI, including those that just print
# out messages.  This is intended to be used across multiple threads, with this running on the "main" thread
# that is allowed to write to the screen.
class Brut::TUI::EventLoop

  # Create a new EventLoop.
  #
  # @param tick [true|false] if true, a "tick" event is fired every 50ms to allow progress spinners to animate.
  def initialize(tick: true)

    @queue = Deque.new

    @queue << Brut::TUI::Events::EventLoopStarted.new

    @event_bus = Brut::TUI::Events::EventBus.new
    @tick = tick
  end

  # Queue an event for later processing. This is safe to do from another thread.
  #
  # @param event [Brut::TUI::Events::BaseEvent] the event to queue.
  def <<(event)
    @queue << event
  end

  # Subscribe to a specific event.  This requires that `subscriber` implement the handler method
  # exposed by {Brut::TUI::Events::BaseEvent.handler_method_name}.  The method's arguments must be 
  # one of three forms:
  #
  # * no-args (or a single `:rest` arg, like `(*)`) - the method is called when the event occurs, no arguments are passed, thus no information about the event is available.
  # * single required arg (e.g. `(event)`) - the event instance is passed.
  # * keyword args (e.g. `(description:, command:)`) - the event is splatted via `deconstruct_keys` and passed in for any keyword arg.  If
  #   required keyword args aren't available from the event, an exception is raised.  If optional keyword args aren't available from the event,
  #   their default values are provided.  Each event should document what keyword args are available.
  #  
  # In all cases, if the method raises an exception, it is captured and sent as a {Brut::TUI::Events::Exception} event, potentially to be
  # handled by other subscribers.  See `#run` for how this interacts with the loop.
  #
  # @param event_class [Class] the event `subscriber` should be notified about. This should be a subclass of {Brut::TUI::Events::BaseEvent}.
  # @param subscriber [Object] object to be notified about the given event.
  def subscribe(event_class, subscriber)
    @event_bus.subscribe(event_class, subscriber)
  end

  # Subscribe to all events.  `subscriber` will only be notified if it
  # implements an event's {Brut::TUI::Events::BaseEvent.handler_method_name} *or* if the subscriber implements
  # `on_any_event`. If both are implemented, only the more specific method is called. See `#subscribe` for a description of
  # how the method is invoked.  If a specific method is not provided, `on_any_event` is invoked with
  # the event instance. There is no keyword splatting in this case.
  #
  # @param subscriber [Object] object to be notified about the given event.
  def subscribe_to_all(subscriber)
    @event_bus.subscribe_to_all(subscriber)
  end

  # Start the event loop.  Don't call this more than once.  It will block and continue running
  # until an event is received that returns true for {Brut::TUI::Events::BaseEvent#exit?}
  # or {Brut::TUI::Events::BaseEvent#drain_then_exit?}.
  #
  # If {Brut::TUI::Events::BaseEvent#exit?} returns true, the loop is exited and any events left
  # in the queue are unprocessed, essentially ignored/discarded.
  #
  # If {Brut::TUI::Events::BaseEvent#drain_then_exit?}
  # returns true, anything currently in the queue is processed before exiting. If any subscriber adds events to the queue
  # they will not be processed. If no event handler produces errors, the CLI should exit cleanly. If, however, any
  # of the event handlers themselves produce errors, those errors will be handled, but the script will exit nonzero.
  def run
    debug "EventLoop: starting"
    start = Time.now
    loop do
      event = @queue.pop(timeout: 0.05)
      debug "EventLoop: got event #{event.class.name}\n                    #{event.inspect}"
      if event
        errors = @event_bus.notify(event)
        debug "EventLoop: notified subscribers of #{event.class.name}, got #{errors.length} errors"

        # future screen rendering here

        handle_errors_from_notify(errors)

        if event.drain_then_exit?
          debug "EventLoop: exiting"
          all_errors = []
          @queue.size.times do
            event = @queue.pop(timeout: 0.05)
            if event
              debug "EventLoop (exiting): got event #{event.class.name}\n                    #{event.inspect}"
              errors = @event_bus.notify(event)
              all_errors = all_errors + errors
              # future screen rendering here
            end
          end
          handle_errors_from_notify(all_errors, immediate: true)
          break
        elsif event.exit?
          debug "EventLoop: exiting"
          break
        end
      end
      if @tick
        errors = @event_bus.notify(Brut::TUI::Events::Tick.new(Time.now - start))
        handle_errors_from_notify(errors)
      end
    end
  end

private

  def handle_errors_from_notify(errors, immediate: false)
    exit_now = immediate || errors.any? { |it| it.kind_of?(Brut::TUI::Events::Exception) && it.exit? }
    if exit_now
      errors.each do
        $stderr.puts("FATAL Exception: #{it.exception.class}: #{it.exception.message}\n    #{it.exception.backtrace.join("\n    ")}")
      end
      exit 1
    else
      errors.each { @queue.unshift(Brut::TUI::Events::Exception.new(it)) }
    end
  end

  def debug(*) = nil#$stderr.puts(*)

  # @!visibility private
  class Deque
    def initialize
      @mutex              = Thread::Mutex.new
      @condition_variable = Thread::ConditionVariable.new
      @array              = []
    end

    def <<(val)
      @mutex.synchronize {
        @array << val
        @condition_variable.signal
      }
    end

    def unshift(val)
      @mutex.synchronize {
        @array.unshift(val)
        @condition_variable.signal
      }
    end

    def pop(timeout:)
      @mutex.synchronize {
        deadline = Time.now + timeout
        while @array.empty?
          remaining = deadline - Time.now
          if remaining <= 0
            return nil 
          end
          @condition_variable.wait(@mutex, remaining)
        end
        @array.shift
      }
    end

    def empty?
      @mutex.synchronize { @array.empty? }
    end

    def size
      @mutex.synchronize { @array.size }
    end
  end

end
