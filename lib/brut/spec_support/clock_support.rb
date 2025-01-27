module Brut::SpecSupport::ClockSupport
  def real_clock = Clock.new(TZInfo::Timezone.get("UTC"))
  def clock_at(now:)
    Clock.new(TZInfo::Timezone.get("UTC"), now: Time.parse(now))
  end
end
