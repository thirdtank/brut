# Convienience methods for creating clocks needed in tests
module Brut::SpecSupport::ClockSupport
  # Return a real lock in UTC
  def real_clock = Clock.new(TZInfo::Timezone.get("UTC"))
  # Return a clock whose value for now is `now`
  #
  # @param [String] now a string containing the value you want for {Clock#now} to return.
  def clock_at(now:)
    Clock.new(TZInfo::Timezone.get("UTC"), now: Time.parse(now))
  end
end
