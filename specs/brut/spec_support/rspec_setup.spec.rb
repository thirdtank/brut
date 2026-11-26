require "spec_helper"
require "tmpdir"
require "fileutils"
require "pathname"
require "sequel"
require "rack-protection"

# This is heavily mocked and mostly tautological but it does
# provide some coverage that this module is not totally borked if
# changes ever get made.
RSpec.describe Brut::SpecSupport::RSpecSetup do
  before do
    @original_semantic_logger_level = SemanticLogger.default_level
    @project_root = Pathname(Dir.mktmpdir("brut-rspec-setup"))
    (@project_root / "specs" / "factories").mkpath
    @app_specs_dir = @project_root / "specs"

    container = Brut::Framework::Container.new
    container.store_required_path("app_specs_dir", "Specs directory", @app_specs_dir)
    container.store("session_class", Class, "Session class", Brut::FrontEnd::Session)
    container.store("flash_class", Class, "Flash class", Brut::FrontEnd::Flash)
    container.store("instrumentation", Object, "Instrumentation", double(record_exception: nil))
    allow(Brut).to receive(:container).and_return(container)

    stub_const("Playwright", Module.new)
    Playwright.const_set(:Test, Module.new)
    Playwright::Test.const_set(:Matchers, Module.new)
  end

  after do
    SemanticLogger.default_level = @original_semantic_logger_level
    Brut::FrontEnd::RequestContext.clear_current!
    FileUtils.remove_entry(@project_root)
  end

  def recording_rspec_config
    Class.new do
      attr_reader :derived_metadata_blocks, :includes, :around_hooks
      def initialize
        @derived_metadata_blocks = []
        @includes = []
        @around_hooks = []
      end
      def define_derived_metadata(&block) = @derived_metadata_blocks.append(block)
      def include(mod, metadata = {}) = @includes.append([mod, metadata])
      def around(&block) = @around_hooks.append(block)
    end.new
  end

  def metadata_for(described_class:, path:, **extra)
    {
      described_class:,
      absolute_file_path: @app_specs_dir / path,
      **extra,
    }
  end

  it "derives component, page, handler, and e2e metadata" do
    config = recording_rspec_config
    described_class.new(rspec_config: config, monkey_patch_summary_notification: false).setup!
    derive_metadata = config.derived_metadata_blocks.fetch(0)

    page_metadata = metadata_for(
      described_class: stub_const("RSpecSetupPage", Class.new),
      path: "front_end/pages/widget_page.spec.rb",
    )
    component_metadata = metadata_for(
      described_class: stub_const("RSpecSetupComponent", Class.new),
      path: "front_end/components/widget_component.spec.rb",
    )
    handler_metadata = metadata_for(
      described_class: stub_const("RSpecSetupHandler", Class.new),
      path: "front_end/handlers/widget_handler.spec.rb",
    )
    e2e_metadata = metadata_for(
      described_class: Class.new,
      path: "e2e/widget_page.spec.rb",
    )

    derive_metadata.(page_metadata)
    derive_metadata.(component_metadata)
    derive_metadata.(handler_metadata)
    derive_metadata.(e2e_metadata)

    expect(page_metadata[:page]).to eq(true)
    expect(page_metadata[:component]).to eq(true)
    expect(component_metadata[:component]).to eq(true)
    expect(component_metadata[:page]).to eq(nil)
    expect(handler_metadata[:handler]).to eq(true)
    expect(e2e_metadata[:e2e]).to eq(true)
  end

  it "includes the support modules with their metadata filters" do
    config = recording_rspec_config
    described_class.new(rspec_config: config, monkey_patch_summary_notification: false).setup!

    expect(config.includes).to eq([
      [Brut::SpecSupport::GeneralSupport, {}],
      [Brut::SpecSupport::CLICommandSupport, { cli_command: true }],
      [Brut::SpecSupport::ComponentSupport, { component: true }],
      [Brut::SpecSupport::HandlerSupport, { handler: true }],
      [Brut::SpecSupport::E2eSupport, { e2e: true }],
      [Playwright::Test::Matchers, { e2e: true }],
    ])
  end

  it "sets up a request context and transaction for handler tests" do
    config = recording_rspec_config
    inside_db_transaction_ran = false
    described_class.new(
      rspec_config: config,
      monkey_patch_summary_notification: false,
    ).setup!(inside_db_transaction: -> { inside_db_transaction_ran = true })
    around_hook = config.around_hooks.fetch(0)

    example_group = Object.new
    lets = {}
    example_group.define_singleton_method(:let) { |name, &block| lets[name] = block }
    example = double(metadata: { handler: true }, example_group: example_group)
    context_during_example = nil
    allow(example).to receive(:run) do
      context_during_example = Brut::FrontEnd::RequestContext.current
    end
    db = Class.new do
      attr_reader :rolled_back
      def transaction
        yield
      rescue Sequel::Rollback
        @rolled_back = true
      end
    end.new
    allow(Sequel::Model).to receive(:db).and_return(db)
    hook_context = Object.new
    hook_context.extend(Brut::SpecSupport::FlashSupport)

    hook_context.instance_exec(example, &around_hook)

    expect(example).to have_received(:run)
    expect(inside_db_transaction_ran).to eq(true)
    expect(db.rolled_back).to eq(true)
    expect(context_during_example).to be_a(Brut::FrontEnd::RequestContext)
    expect(lets[:request_context].call).to equal(context_during_example)
  end

  it "clears the request context after an example that used one" do
    config = recording_rspec_config
    described_class.new(
      rspec_config: config,
      monkey_patch_summary_notification: false,
    ).setup!
    around_hook = config.around_hooks.fetch(0)
    db = Class.new do
      def transaction
        yield
      rescue Sequel::Rollback
        nil
      end
    end.new
    allow(Sequel::Model).to receive(:db).and_return(db)
    hook_context = Object.new
    hook_context.extend(Brut::SpecSupport::FlashSupport)

    [ { handler: true }, { component: true }, { page: true } ].each do |metadata|
      example_group = Object.new
      example_group.define_singleton_method(:let) { |_name, &_block| nil }
      example = double(metadata:, example_group: example_group)
      allow(example).to receive(:run)

      hook_context.instance_exec(example, &around_hook)

      expect(Brut::FrontEnd::RequestContext.current).to be_nil
    end
  end

  describe described_class::OptionalSidekiqSupport do
    it "yields without doing anything else when Sidekiq is not loaded" do
      hide_const("Sidekiq") if defined?(Sidekiq)
      support = described_class.new
      block_ran = false

      support.disable_sidekiq_testing { block_ran = true }
      support.clear_background_jobs

      expect(block_ran).to eq(true)
    end

    it "disables Sidekiq testing, flushes Redis, and clears background jobs when Sidekiq is loaded" do
      calls = []
      redis = Object.new
      redis.define_singleton_method(:flushall) { calls << :flushall }
      sidekiq_testing = Module.new
      sidekiq_testing.define_singleton_method(:disable!) do |&block|
        calls << :disable!
        block.call
      end
      sidekiq_worker = Module.new
      sidekiq_worker.define_singleton_method(:clear_all) { calls << :clear_all }
      sidekiq = Module.new
      sidekiq.const_set(:Testing, sidekiq_testing)
      sidekiq.const_set(:Worker, sidekiq_worker)
      sidekiq.define_singleton_method(:redis) do |&block|
        calls << :redis
        block.call(redis)
      end
      stub_const("Sidekiq", sidekiq)
      support = described_class.new
      block_ran = false

      support.disable_sidekiq_testing { block_ran = true }
      support.clear_background_jobs

      expect(block_ran).to eq(true)
      expect(calls).to eq([:disable!, :redis, :flushall, :clear_all])
    end
  end
end
