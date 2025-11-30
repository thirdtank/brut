# @!visibility private
class Brut::TUI::Events::EventBus
  def initialize
    @subscribers = {}
  end

  # Notify all subscribers of the given event.
  def notify(event)
    handler_method_name = event.class.handler_method_name

    errors = []

    subscribers(event.class).each do |subscriber|
      begin
        subscriber.send(handler_method_name, event)
      rescue => ex
        errors << ex
      end
    end

    subscribers(:all).each do |subscriber|
      begin
        if subscriber.respond_to?(handler_method_name)
          params = subscriber.method(handler_method_name).parameters
          if params.size == 0 || (params.size == 1 && params[0][0] == :rest)
            subscriber.send(handler_method_name)
          elsif params.size == 1 && params[0][0] == :req
            subscriber.send(handler_method_name, event)
          elsif params.all? { |it| it[0] == :keyreq || it[0] == :key }
            param_keys = params.map { |it| it[1] }
            args = event.deconstruct_keys.slice(*param_keys)
            subscriber.send(handler_method_name, **args)
          else
            raise "#{subscriber.class}##{handler_method_name} has unsupported parameters. It must take either zero parameters, one required parameter (the event), or keyword parameters matching the event's attributes. Method's parameters: #{params.inspect}"
          end
        elsif subscriber.respond_to?(:on_any_event)
          params = subscriber.method(:on_any_event).parameters
          if params.size == 1 && (params[0][0] == :req || params[0][0] == :rest)
            subscriber.on_any_event(event)
          else
            raise "#{subscriber.class}#on_any_event has unsupported parameters. It must take one required parameter (the event). Method's parameters: #{params.inspect}"
          end
        end
      rescue => ex
        errors << ex
      end
    end
    errors
  end

  # Subscribe to all events the subscriber can handle. If the subscriber implements
  # the event's handler_method_name method, it will be called when the event is fired.
  # If the subscriber implements on_any_event, that method will be called for every event.
  def subscribe_to_all(subscriber)
    subscribers(:all) << subscriber
  end

  # Subscribe to a specific event class. The subscriber must implement the event's
  # handler_method_name method.
  def subscribe(event_class, subscriber)
    if subscriber.respond_to?(event_class.handler_method_name)
      subscribers(event_class) << subscriber
    else
      raise ArgumentError, "Subscriber #{subscriber} does not implement handler method #{event_class.handler_method_name} for event #{event_class}"
    end
  end

private

  def subscribers(event_class_or_all)
    @subscribers[event_class_or_all] ||= []
  end
end
