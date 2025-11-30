# An event that indicates time has passed.
class Brut::TUI::Events::Tick < Brut::TUI::Events::BaseEvent
  def initialize(elapsed_time)
    @elapsed_time = elapsed_time
  end

  # Includes `elapsed_time`, which is the number of seconds since the
  # event loop started.
  def deconstruct_keys(keys=nil)
    super.merge({ elapsed_time: @elapsed_time })
  end
end
