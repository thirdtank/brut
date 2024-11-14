class Brut::Instrumentation::Basic
  def initialize
    @subscribers = Concurrent::Set.new
  end

  class TypeChecking < Brut::Instrumentation::Basic
    def instrument(event,&block)
      if !event.kind_of?(Brut::Instrumentation::Event)
        raise "You cannot instrument a #{event.class} - it must be a Brut::Instrumentation::Event or subclass"
      end
      super
    end
  end

  def instrument(event,&block)
    block ||= ->() {}

    start     = Time.now
    result    = nil
    exception = nil

    begin
      result = block.(event)
    rescue => ex
      exception = ex
    end
    stop = Time.now
    notify(event:,start:,stop:,exception:)
    if exception
      raise exception
    else
      result
    end
  end

  def subscribe(subscriber=:use_block,&block)
    if block.nil? && subscriber == :use_block
      raise ArgumentError,"subscriber requires a Brut::Instrumentation::Subscriber or a block"
    end
    if !block.nil? && subscriber != :use_block
      raise ArgumentError,"subscriber requires a Brut::Instrumentation::Subscriber or a block, not both"
    end
    if block.nil?
      if subscriber.kind_of?(Proc)
        subscriber = Brut::Instrumentation::Subscriber.from_proc(subscriber)
      elsif !subscriber.kind_of?(Brut::Instrumentation::Subscriber)
        raise ArgumentError, "subscriber must be a Proc or Brut::Instrumentation::Subscriber, not a #{subscriber.class}"
      end
    else
      subscriber = Brut::Instrumentation::Subscriber.from_proc(block)
    end
    @subscribers << subscriber
  end

  def notify(event:,start:,stop:,exception:)
    Thread.new do
      @subscribers.each do |subscriber|
        begin
          subscriber.(event:,start:,stop:,exception:)
        rescue => ex
          warn "#{subscriber} raised #{ex}"
        end
      end
    end
  end
end
