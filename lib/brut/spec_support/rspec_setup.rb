# Configures RSpec for Brut.  This provides several bits of infrastructure only present when the app is running, as well as
# quality of life improvements to make testing Brut components a bit easier.  Even though Brut classes are all normal classes, it's
# convenient to have extraneous classes set up for you.
#
# * Metadata is added based on the class names under test:
#   - `*Component` -> `:component`
#   - `*Page` -> `:component`
#   - `*Page` -> `:page`
#   - `*Handler` -> `:handler`
#   - If you add the `:page` metadata automatically, `:component` is added as well.
#   - Tests in `specs/e2e` or any subfolder -> `:e2e`
#   - Note that you are free to explicitly add these tags to your test metadata. That will cause the inclusion of modules as described below
# * Modules are included to provide additional support for writing tests:
#   - {Brut::SpecSupport::GeneralSupport} included in all tests
#   - {Brut::SpecSupport::ComponentSupport} included when `:component` metadata is set (generally, this is for page and component tests)
#   - {Brut::SpecSupport::HandlerSupport} included when `:handler` is set.
#   - {Playwright::Test::Matchers{ included when `:e2e` is set, which allows use of the Ruby binding for Playwright.
# * Non end-to-end tests will be run inside a database transaction to allow all database changes to be instantly undone.  This does
# mean that any tests that tests database transaction behavior will not work as expected.
# * In component tests (which generally includes page tests), a {Brut::FrontEnd::RequestContext} is created for you and placed into
# the thread local storage.  This allows any component that is injected with data from the `RequestContext` to access it as it would
# normally.  You can also seed this with data that a component may need.
# * Handles all infrastructure for end-to-end tests:
#   - starting a test server using {Brut::SpecSupport::E2ETestServer}
#   - launching Chromium via Playwright
# * If using Sidekiq:
#   - Jobs are cleared before each test
#   - For end-to-end tests, Redis is flushed and actual Sidekiq is used instead of testing mode
#
# You can set certain metadata to change behavior:
#
# * `e2e_timeout` - number of milliseconds to wait until an end-to-end test gives up on a selector being found.  The default is 5,000 (5 seconds). Use this only if there's no other way to keep your test from needing more than 5 seconds.
#
#
# @example
#     RSpec.configure do |config|
#       rspec_setup = Brut::SpecSupport::RSpecSetup.new(rspec_config: config)
#       rspec_setup.setup!
#
#       # rest of the RSpec configuration
#     end
class Brut::SpecSupport::RSpecSetup
  # Create the setup with the given RSpec configuration.
  #
  # @param [RSpec::Core::Configuration] rspec_config yielded from `RSpec.configure`
  def initialize(rspec_config:)
    @config = rspec_config
    SemanticLogger.default_level = ENV.fetch("LOGGER_LEVEL_FOR_TESTS","warn")
  end

  # Sets up RSpec with variouis configurations needed by Brut to run your tests.
  #
  # @param [Proc] inside_db_transaction if given, this is run inside the DB transaction before your example is run. This is useful if you need to set up some reference data for all tests.
  def setup!(inside_db_transaction: ->() {})

    Brut::FactoryBot.new.setup!
    optional_sidekiq_support = OptionalSidekiqSupport.new

    @config.define_derived_metadata do |metadata|
      if metadata[:described_class].to_s =~ /[a-z0-9]Component$/ ||
          metadata[:described_class].to_s =~ /[a-z0-9]Page$/ ||
          metadata[:page] == true
        metadata[:component] = true
      end
      if metadata[:described_class].to_s =~ /[a-z0-9]Page$/ ||
          metadata[:page] == true
        metadata[:page] = true
      end
      if metadata[:described_class].to_s =~ /[a-z0-9]Handler$/
        metadata[:handler] = true
      end

      relative_path = Pathname(metadata[:absolute_file_path]).relative_path_from(Brut.container.app_specs_dir)

      top_level_directory = relative_path.each_filename.to_a[0].to_s
      if top_level_directory == "e2e"
        metadata[:e2e] = true
      end
    end
    @config.include Brut::SpecSupport::GeneralSupport
    @config.include Brut::SpecSupport::ComponentSupport, component: true
    @config.include Brut::SpecSupport::HandlerSupport, handler: true
    @config.include Playwright::Test::Matchers, e2e: true

    @config.around do |example|

      needs_request_context = example.metadata[:component] ||
                              example.metadata[:handler]   ||
                              example.metadata[:page]

      if needs_request_context
        session = {
          "session_id" => "test-session-id",
          "csrf" => "test-csrf-token"
        }
        env = {
          "rack.session" => session
        }
        app_session = Brut.container.session_class.new(rack_session: session)
        request_context = Brut::FrontEnd::RequestContext.new(
          env: env,
          session: app_session,
          flash: empty_flash,
          body: nil,
          xhr: false,
        )
        Thread.current.thread_variable_set(:request_context, request_context)
        example.example_group.let(:request_context) { request_context }
      end
      if example.metadata[:component]
        example.example_group.let(:component_name) { described_class.component_name }
      end
      if example.metadata[:page]
        example.example_group.let(:page_name) { described_class.page_name }
      end

      if example.metadata[:e2e]
        e2e_timeout = (ENV["E2E_TIMEOUT_MS"] || example.metadata[:e2e_timeout] || 5_000).to_i
        optional_sidekiq_support.disable_sidekiq_testing do
          Brut::SpecSupport::E2ETestServer.instance.start
          Playwright.create(playwright_cli_executable_path: "./node_modules/.bin/playwright") do |playwright|
            launch_args = {
              headless: true,
            }
            if ENV["E2E_SLOW_MO"]
              launch_args[:slowMo] = ENV["E2E_SLOW_MO"].to_i
            end
            playwright.chromium.launch(**launch_args) do |browser|
              context_options = {
                baseURL: "http://0.0.0.0:6503/",
              }
              if ENV["E2E_RECORD_VIDEOS"]
                context_options[:record_video_dir] = Brut.container.tmp_dir / "e2e-videos"
              end
              browser_context = browser.new_context(**context_options)
              browser_context.default_timeout = e2e_timeout
              example.example_group.let(:page) { browser_context.new_page }
              example.run
              browser_context.close
              browser.close
            end
          end
        end
      else
        optional_sidekiq_support.clear_background_jobs
        Sequel::Model.db.transaction do
          inside_db_transaction.()
          example.run
          raise Sequel::Rollback
        end
      end
    end
    @config.after(:suite) do
      Brut::SpecSupport::E2ETestServer.instance.stop
    end
  end

  class OptionalSidekiqSupport
    def initialize
      @sidekiq_in_use = defined?(Sidekiq)
    end

    def disable_sidekiq_testing(&block)
      if @sidekiq_in_use
        Sidekiq::Testing.disable! do
          Sidekiq.redis do |redis|
            redis.flushall
          end
          block.()
        end
      else
        block.()
      end
    end
    def clear_background_jobs
      if @sidekiq_in_use
        Sidekiq::Worker.clear_all
      end
    end
  end

end
