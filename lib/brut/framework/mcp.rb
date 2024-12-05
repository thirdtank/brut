require_relative "container"
require_relative "config"
require_relative "../junk_drawer"
require_relative "app"
require "sequel"
require "semantic_logger"
require "i18n"
require "zeitwerk"

# The Master Control Program of Brut.  This handles all the bootstrapping and setup of your app. You are not
# intended to use or interact with this class at all. End of line.
class Brut::Framework::MCP

  # Create the MCP.
  #
  # @param [Class] app_klass subclass of {Brut::Framework::App} representing the Brut app being started up and managed.
  def initialize(app_klass:)
    @config    = Brut::Framework::Config.new
    @booted    = false
    @loader    = Zeitwerk::Loader.new
    @app_klass = app_klass
    self.configure!
  end

  # Configure Brut and initialize the {Brut::Framework::App} subclass. This should, in theory, only set up values and other
  # ancillary data needed to start the app. It should not connect to databases.
  def configure!
    @config.configure!

    project_root = Brut.container.project_root
    project_env  = Brut.container.project_env

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

    i18n_locales_dir = Brut.container.i18n_locales_dir
    locales = Dir[i18n_locales_dir / "*"].map { |_|
      Pathname(_).basename
    }
    ::I18n.load_path += Dir[i18n_locales_dir / "**/*.rb"]
    ::I18n.available_locales = locales.map(&:to_s).map(&:to_sym)

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
    @app = @app_klass.new
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
    Sequel::Database.extension :brut_instrumentation

    sequel_db = Brut.container.sequel_db_handle

    Sequel::Model.db = sequel_db

    Sequel::Model.plugin :find_bang
    Sequel::Model.plugin :created_at

    if !Brut.container.external_id_prefix.nil?
      Sequel::Model.plugin :external_id, global_prefix: Brut.container.external_id_prefix
    end
    if Brut.container.eager_load_classes?
      SemanticLogger["Brut"].info("Eagerly loading app's classes")
      @loader.eager_load
    else
      SemanticLogger["Brut"].info("Lazily loading app's classes")
    end
    Brut.container.instrumentation.subscribe do |event:,start:,stop:,exception:|
      SemanticLogger["Instrumentation"].info("#{event.category}/#{event.subcategory}/#{event.name}: #{start}/#{stop} = #{stop-start}: #{exception&.message} (#{event.details})")
    end
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

    middlewares = default_middlewares + @app.class.middleware

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
          result = hook.send(method,**args)
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
    @app.class.routes.each do |route_block|
      @sinatra_app.instance_eval(&route_block)
    end

    @booted = true
  end
  # @!visibility private
  def sinatra_app = @sinatra_app
  # @!visibility private
  def app = @app

end
