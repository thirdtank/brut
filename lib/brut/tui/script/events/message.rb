# Fired when a step produces a message
class Brut::TUI::Script::Events::Message < Brut::TUI::Events::BaseEvent
  def initialize(message:, type:)
    @message = message
    @type    = type
  end

  def to_s = @message

  # Includes `message` and `type`. `type` will be `:notify`, `:warning`, `:success`,
  # `:error`, or `:done`, however it could be anything else the script may choose to use.
  def deconstruct_keys(keys=nil)
    super.merge({ message: @message, type: @type })
  end
end
