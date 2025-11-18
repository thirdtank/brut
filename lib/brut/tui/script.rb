require "logger"
require "fileutils"

# A TUI script is a set of steps that are executed in order.  Steps
# can be grouped int phases, and each step can either shell out
# to an external command or execute Ruby code.
#
# You are intended to subclass this class and implement `#execute`, which can use
# the various methods described here to describe the script.  In the context of a 
# Brut CLI, your subclass would be used inside the {Brut::CLI::Command#execute} method, where
# it would call `#run!` (not `#execute`).
#
# Inside `#execute` you should call `#phase` for each logical phase/grouping of steps. There must be at least
# one phase.  Inside each `phase` you should call `#step` one or more times.  When a phase is actually executed,
# it's contents are executed, so anything inside the block will be called.  Intermediate variables to allow `step`s to
# communicate will work.
#
# After all phases, call `done` with a success message.
#
# @example
#     def execute
#       phase "Set up test data" do
#         step "Initializing database",
#              exec: "bin/db rebuild -e test"
#         step "Loading data" do
#           MyData.each do |data|
#             notify "Inserting #{data}"
#             data.insert!
#           end
#         end
#       end
#       phase "Checking data integrity" do
#         problems = []
#         step "Analyzing data" do
#           MyData.each do |data|
#             if !data.analyze
#               problems << data
#             end
#           end
#         end
#         step "Checking problems" do
#           abort = false
#           problems.each do |problem|
#             if problem.warning?
#               warning "#{problem} may be an issue, but we can proceed"
#             else
#               error "#{problem} will prevent our test from working"
#               abort = true
#             end
#           end
#           if abort
#             raise "Problems prevented script from working"
#           end
#         end
#       end
#       
#       done "All ready to go!"
#     end
class Brut::TUI::Script

  autoload(:Step              , "brut/tui/script/step")
  autoload(:BlockStep         , "brut/tui/script/block_step")
  autoload(:ExecStep          , "brut/tui/script/exec_step")
  autoload(:LoggingSubscriber , "brut/tui/script/logging_subscriber")
  autoload(:PutsSubscriber    , "brut/tui/script/puts_subscriber")
  autoload(:Events            , "brut/tui/script/events")

  # Return the basename of a log file unique to this script. This will use
  # the subclass name to come up with a reasonable name, however your
  # class can override this.
  def self.log_filename
    name = self.name.gsub(/Script$/,"").gsub(/::$/,"").split("::").last
    name.gsub(/([a-z])([A-Z])/, '\1_\2').downcase
  end

  # Create the script. By default, two subscribers are set up: {Brut::TUI::Script::LoggingSubscriber}
  # and {Brut::TUI::Script::PutsSubscriber}.  The logging subscriber will output a detailed
  # log into `logs/` using the file named by {.log_filename}.  The `PutsSubscriber` will
  # output ANSI-Fancy messages as the script proceeds.
  #
  # @param root_dir [String|Pathname] path to the root of the Brut project.
  # @param ansi [true|false] if true, the {Brut::TUI::Script::PutsSubscriber} will use
  #        ANSI escape codes to format the output. If false, it won't.
  def initialize(root_dir: nil, ansi: true)
    @root_dir = root_dir ? Pathname(root_dir).expand_path : nil
    logs_dir = if @root_dir
                @root_dir / "logs" 
              else
                Pathame(".") / "logs"
              end
    FileUtils.mkdir_p(logs_dir)
    @event_loop = Brut::TUI::EventLoop.new

    logging_subscriber = LoggingSubscriber.new($0, logfile: logs_dir / "#{self.class.log_filename}.log")
    terminal = Brut::TUI::Terminal.new
    theme = if ansi
               Brut::TUI::TerminalTheme.based_on_background(terminal)
             else
               Brut::TUI::Themes::None.new(terminal)
             end
    puts_subscriber = Brut::TUI::Script::PutsSubscriber.new($0, terminal:, theme:)

    @event_loop.subscribe(Brut::TUI::Events::EventLoopStarted,self)
    @event_loop.subscribe_to_all(logging_subscriber)
    @event_loop.subscribe_to_all(puts_subscriber)

  end

  # @!visibility private
  def on_event_loop_started(event)
    Thread.new do
      begin
        @phases = []
        self.execute
        @event_loop << Events::ScriptStarted.new(phases: @phases)
        @phases.each_with_index do |(name,block), index|
          step_number = index + 1
          @event_loop << Events::PhaseStarted.new(name, step_number: step_number, total_steps: @phases.length)
          block.()
          @event_loop << Events::PhaseCompleted.new(name, step_number: step_number, total_steps: @phases.length)
        end
        @event_loop << Events::Message.new(message: @done_message || "Script completed successfully", type: :done)
      rescue => ex
        @event_loop << Brut::TUI::Events::Exception.new(ex)
      end
      @event_loop << Events::ScriptCompleted.new
    end
  end

  # Entry point for a script. This method starts the event loop.
  def run!
    if !self.methods.include?(:execute)
      raise "You must implement the execute method in your Brut::TUI::Script subclass"
    end
    @event_loop.run
    0
  end

  # Create a new phase for the script. A phase is basically a named group
  # of steps.  The block is not executed immediately, so you may not pass
  # data from one phase to another.
  #
  # @param name [String] The name of the phase
  # @param block [Proc] The block to execute for the phase
  def phase(name, &block)
    @phases << [ name, block ]
  end

  # A step to run inside a phase.  Steps within phases are executed immediately once the phase
  # has started, so they can pass data to one anther.
  #
  # @param description [String] Message to show the user about this step.
  # @param exec [String|nil] if non-nil, this step will execute this as a command.  A block given is ignored.
  #        If `nil`, a block should be given that contains the step's code.
  # @yield if `exec` is `nil`, this block will be executed for the step
  def step(description, exec: nil, &block)
    step = if exec.nil?
             BlockStep.new(@event_loop, description, &block)
           else
             ExecStep.new(@event_loop, description, command: exec)
           end
    step.run!
  end

  # Notify the user of an event
  #
  # @param message [String] Message to show
  def notify(message)
    @event_loop << Events::Message.new(message:, type: :notification)
  end

  # Warn the user of an event
  #
  # @param message [String] Message to show
  def warning(message)
    @event_loop << Events::Message.new(message:, type: :warning)
  end

  # Let the user know something succeeded
  #
  # @param message [String] Message to show
  def success(message)
    @event_loop << Events::Message.new(message:, type: :success)
  end

  # Message to show if the script completes successful.  Should only be called once
  # and not inside a phase or step.
  #
  # @param message [String] Message to show
  def done(message)
    @done_message = message
  end

  # Let the user know there was an error. Note that this will not stop
  # the script.  Raise an exception to do that.
  #
  # @param message [String] Message to show
  def error(message)
    @event_loop << Events::Message.new(message:, type: :error)
  end

  # Wrap a fully-qualified filename in code markup and trim the path to only
  # show the path relative to the root dir.  This is much friendlier than showing a
  # long expanded path.
  #
  # @param path [String|Pathname] a fully-qualified path to something inside your Brut app.
  def filename(path)
    path = Pathname(path).expand_path
    "`" + (@root_dir ? path.relative_path_from(@root_dir) : path).to_s + "`"
  end
end
