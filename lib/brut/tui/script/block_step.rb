# A step whose behavior is a given block of code.
# Fires {Brut::TUI::Script::Events::StepStarted} before
# the code executes and {Brut::TUI::Script::Events::StepCompleted}
# *only* if the block completes without an exception being thrown.
class Brut::TUI::Script::BlockStep < Brut::TUI::Script::Step
  def initialize(event_loop, description, &block)
    super(event_loop, description)
    @block = block
  end

  def run!
    event_loop << Events::StepStarted.new(step: self)
    @block.().tap {
      event_loop << Events::StepCompleted.new(step: self)
    }
  end
end
