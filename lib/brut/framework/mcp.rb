require_relative "container"
require_relative "config"
require_relative "../junk_drawer"
require_relative "app"

require "sequel"

require "semantic_logger"
require_relative "patch_semantic_logger"

require "i18n"
require "zeitwerk"
require "opentelemetry/sdk"
require "opentelemetry/exporter/otlp"

# The Master Control Program of Brut.  This handles all the bootstrapping and setup of your app. You are not
# intended to use or interact with this class at all. End of line.
class Brut::Framework::MCP

  # Create and configure the MCP.  The app will not work until {#boot!} has been called, however most of the core configuration
  # will be available via `Brut.container`.
  #
  # In particular, when this initializer is done, the following will be set up:
  #
  # * Logging
  # * I18n
  # * Zeitwerk
  # * Initial values and configuration from {Brut::Framework::Config#configure!}.  Note that some values in there are static and some
  # are lazily-evaluated, i.e. their values will only be calculated when fetched.
  #
  # In general, you shouldn't have to interact with this class directly, however for posterity, there are basically two ways in which
  # to do so:
  #
  # * Create the instance and *do not* call `boot!`.  This is what you'd do if you can't or don't want to connect to external services
  # like the database.  For example, when Brut builds assets, it does not call `boot!`.
  # * Create the intance and immediately call `boot!`.  This is what happens most of the time, in particular when the app is started
  # up by Puma to start serving requests.
  #
  # What you should avoid doing is creating an instance of this class and performing logic before later calling `boot!`.
  #
  # @param [Class] app_klass subclass of {Brut::Framework::App} representing the Brut app being started up and managed.
  def initialize(app_klass:)
    @config    = Brut::Framework::Config.new
    @booted    = false
    @loader    = Zeitwerk::Loader.new
    @config.configure!

    setup_logging
    setup_i18n
    setup_zeitwerk

    @app = app_klass.new
  end

  # Starts up the internals of Brut and that app so that it can receive requests from
  # the web server.  This *can* make network connections to establish connectivity
  # to external resources.
  def boot!
    if @booted
      raise "already booted!"
    end
    if Brut.container.debug_zeitwerk?
      @loader.log!
    end
    Kernel.at_exit do
      begin
        Brut.container.sequel_db_handle.disconnect
      rescue Sequel::DatabaseConnectionError
        SemanticLogger["Sequel::Database"].info "Not connected to database, so not disconnecting"
      end
    end
    Sequel::Database.extension :pg_array

    sequel_db = Brut.container.sequel_db_handle

    Sequel::Model.db = sequel_db

    Sequel::Model.plugin :find_bang
    Sequel::Model.plugin :created_at
    Sequel::Model.plugin :table_select
    Sequel::Model.plugin :skip_saving_columns

    if !Brut.container.external_id_prefix.nil?
      Sequel::Model.plugin :external_id, global_prefix: Brut.container.external_id_prefix
    end
    if Brut.container.eager_load_classes?
      SemanticLogger["Brut"].info("Eagerly loading app's classes")
      @loader.eager_load
    else
      SemanticLogger["Brut"].info("Lazily loading app's classes")
    end
    OpenTelemetry::SDK.configure do |c|
      c.service_name = @app.id
      if ENV["OTEL_TRACES_EXPORTER"]
        SemanticLogger[self.class].info "OTEL_TRACES_EXPORTER was set (to '#{ENV['OTEL_TRACES_EXPORTER']}'), so Brut's OTel logging is disabled"
      else
        c.add_span_processor(
          OpenTelemetry::SDK::Trace::Export::SimpleSpanProcessor.new(
            Brut::Instrumentation::LoggerSpanExporter.new
          )
        )
      end

      if defined?(OpenTelemetry::Instrumentation::Sidekiq)
        c.use 'OpenTelemetry::Instrumentation::Sidekiq', {
          span_naming: :job_class,
        }
      else
        SemanticLogger[self.class].info "OpenTelemetry::Instrumentation::Sidekiq is not loaded, so Sidekiq traces will not be captured"
      end
    end

    Brut.container.store(
      "tracer",
      OpenTelemetry::SDK::Trace::Tracer,
      "Tracer for Open Telemetry",
      OpenTelemetry.tracer_provider.tracer(@app.id)
    )
    Sequel::Database.extension :brut_instrumentation

    @app.boot!

    require "sinatra/base"

    @sinatra_app = Class.new(Sinatra::Base)
    @sinatra_app.include(Brut::SinatraHelpers)

    message = if Brut.container.project_env.development?
                "Form submission did not include an authenticity token. All forms must include one. To add one, use the `form_tag` helper, or include <%= component(Brut::FrontEnd::Components::Inputs::CsrfToken) %> somewhere inside your <form> tag"
              else
                "Forbidden"
              end
    default_middlewares = [
      [ Brut::FrontEnd::Middlewares::OpenTelemetrySpan ],
      [ Brut::FrontEnd::Middlewares::AnnotateBrutOwnedPaths ],
      [ Brut::FrontEnd::Middlewares::Favicon ],
      [
        Rack::Protection::AuthenticityToken,
        [
          {
            allow_if: ->(env) { env["brut.owned_path"] },
            message: message,
          }
        ]
      ],
    ]
    if Brut.container.auto_reload_classes?
      default_middlewares << Brut::FrontEnd::Middlewares::ReloadApp
    end

    middlewares = default_middlewares + @app.class.middleware.map { |(middleware,args,block)|
      if !middleware.kind_of?(Class)
        klass = middleware.to_s.split(/::/).reduce(Module) { |mod,part|
          mod.const_get(part)
        }
        [ klass, args, block ]
      else
        [ middleware, args, block ]
      end
    }

    middlewares.each do |(middleware,args,block)|
      @sinatra_app.use(middleware,*args,&block)
    end
    befores = [
      Brut::FrontEnd::RouteHooks::SetupRequestContext,
      Brut::FrontEnd::RouteHooks::LocaleDetection,
    ] + @app.class.before

    afters = [
      Brut::FrontEnd::RouteHooks::AgeFlash,
      Brut.container.csp_class,
      Brut.container.csp_reporting_class,
    ].compact + @app.class.after

    [
      [ befores, :before ],
      [ afters,  :after  ],
    ].each do |hooks,method|
      hooks.each do |klass_name|
        klass = klass_name.to_s.split(/::/).reduce(Module) { |mod,part|
          mod.const_get(part)
        }
        hook_method = klass.instance_method(method)
        @sinatra_app.send(method) do
          args = {}

          Brut.container.instrumentation.span("#{klass_name}.#{method}") do |span|
            hook_method.parameters.each do |(type,name)|
              if name.to_s == "**" || name.to_s == "*"
                raise ArgumentError,"#{method.class}##{method.name} accepts '#{name}' and not keyword args. Define it in your class to accept the keyword arguments your method needs"
              end
              if ![ :key,:keyreq ].include?(type)
                raise ArgumentError,"#{name} is not a keyword arg, but is a #{type}"
              end

              if name == :request_context
                args[name] = Thread.current.thread_variable_get(:request_context)
              elsif name == :session
                args[name] = Brut.container.session_class.new(rack_session: session)
              elsif name == :request
                args[name] = request
              elsif name == :response
                args[name] = response
              elsif name == :env
                args[name] = env
              elsif type == :keyreq
                raise ArgumentError,"#{method} argument '#{name}' is required, but it's not available in a #{method} hook"
              else
                # this keyword arg has a default value which will be used
              end
            end

            hook = klass.new
            span.add_prefixed_attributes("#{method}.args",args.map { |k,v| [ k,v.class] }.to_h )
            result = hook.send(method,**args)
            span.add_attributes(result:)
            case result
            in URI => uri
              redirect to(uri.to_s)
            in Brut::FrontEnd::HttpStatus => http_status
              halt http_status.to_i
            in FalseClass
              halt 500
            in NilClass
              nil
            in TrueClass
              nil
            else
              raise NoMatchingPatternError, "Result from #{method} hook #{klass}'s #{method} method was a #{result.class} (#{result.to_s} as a string), which cannot be used to understand the response to generate. Return nil or true if processing should proceed"
            end
          end
        end
      end
    end
    @app.class.routes.each do |route_block|
      @sinatra_app.instance_eval(&route_block)
    end

    @booted = true
  end

  # @!visibility private
  def sinatra_app = @sinatra_app
  # @!visibility private
  def app = @app

private

  def setup_logging
    SemanticLogger.default_level = Brut.container.log_level
    semantic_logger_appenders = Brut.container.semantic_logger_appenders
    if semantic_logger_appenders.kind_of?(Hash)
      semantic_logger_appenders = [ semantic_logger_appenders ]
    end
    if semantic_logger_appenders.length == 0
      raise "No loggers are set up - something is wrong"
    end
    semantic_logger_appenders.each do |appender|
      SemanticLogger.add_appender(**appender)
    end
    SemanticLogger["Brut"].info("Logging set up")
  end

  def setup_i18n

    i18n_locales_dir = Brut.container.i18n_locales_dir
    locales = Dir[i18n_locales_dir / "*"].map { Pathname(it).basename }
    ::I18n.load_path += Dir[i18n_locales_dir / "**/*.rb"]
    ::I18n.available_locales = locales.map(&:to_s).map(&:to_sym)
  end

  def setup_zeitwerk

    Brut.container.store(
      "zeitwerk_loader",
      @loader.class,
      "Zeitwerk Loader configured for this app",
      @loader
    )

    Dir[Brut.container.front_end_src_dir / "*"].each do |dir|
      if Pathname(dir).directory?
        @loader.push_dir(dir)
      end
    end
    Dir[Brut.container.back_end_src_dir / "*"].each do |dir|
      if Pathname(dir).directory?
        @loader.push_dir(dir)
      end
    end
    @loader.ignore(Brut.container.migrations_dir)
    @loader.ignore(Brut.container.db_seeds_dir)
    @loader.inflector.inflect(
      "db" => "DB"
    )
    if Brut.container.auto_reload_classes?
      SemanticLogger["Brut"].info("Auto-reloaded configured")
      @loader.enable_reloading
    else
      SemanticLogger["Brut"].info("Classes will not be auto-reloaded")
    end

    @loader.setup
  end
end
