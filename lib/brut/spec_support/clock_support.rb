# Convienience methods for creating clocks needed in tests
module Brut::SpecSupport::ClockSupport
  # Return a real lock in UTC
  def real_clock = Clock.new(TZInfo::Timezone.get("UTC"))

  # Return a clock whose value for now is `now`, in UTC
  #
  # @param [String] now a string containing the value you want for {Clock#now} to return.
  def clock_at(now:)
    self.clock_in_timezone_at(timezone_name: "UTC", now: now)
  end

  # Return a clock whose value for now is `now` in the given timezone
  #
  # @param [String] timezone_name a string that is the name of the timezone to use.
  # @param [String] now a string containing the value you want for {Clock#now} to return.
  def clock_in_timezone_at(timezone_name:, now:)
    time = Time.parse(now)
    timezone = TZInfo::Timezone.get(timezone_name)
    same_time_in_timezone = timezone.local_time(time.year, time.month, time.day, time.hour, time.min, time.sec)

    Clock.new(TZInfo::Timezone.get(timezone_name), now: same_time_in_timezone)
  end
end
