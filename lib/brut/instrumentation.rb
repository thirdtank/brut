module Brut::Instrumentation
  autoload(:Basic,"brut/instrumentation/basic")
  autoload(:Subscriber,"brut/instrumentation/subscriber")
  autoload(:Event,"brut/instrumentation/event")
  autoload(:HTTPEvent,"brut/instrumentation/http_event")

  def instrument(**args,&block)
    Brut.container.instrumentation.instrument(Brut::Instrumentation::Event.new(**args),&block)
  end
end

