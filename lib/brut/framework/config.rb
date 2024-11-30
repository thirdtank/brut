require_relative "project_environment"
require "pathname"

# Exists to hold configuration for the Brut framework.
# This is a wrapper around a series of calls to Brut.container.store
# but is a class and thus invokable, so that the configuration can
# be controlled.
class Brut::Framework::Config

  class DockerPathComponent
    PATH_REGEXP = /\A[a-z0-9]+(-|_)?[a-z0-9]+\z/
    def initialize(string)
      if string.to_s.match?(PATH_REGEXP)
        @string = string
      else
        raise ArgumentError.new("Value must be only lower case letters, digits, and may have at most one underscore: '#{string}'")
      end
    end

    def to_str = @string
    def to_s = self.to_str
  end

  class AppId < DockerPathComponent
  end

  class AppOrganizationName < DockerPathComponent
  end

  def configure!
    Brut.container do |c|
      # Brut Stuff that should not be changed

      c.store_ensured_path(
        "tmp_dir",
        "Temporary directory where ephemeral files can do"
      ) do |project_root|
        project_root / "tmp"
      end

      c.store(
        "project_env",
        Brut::Framework::ProjectEnvironment,
        "The environment of the running app, e.g. dev/test/prod",
        Brut::Framework::ProjectEnvironment.new(ENV["RACK_ENV"])
      )

      c.store_ensured_path(
        "log_dir",
        "Path where log files may be written"
      ) do |project_root|
        project_root / "logs"
      end

      c.store_ensured_path(
        "public_root_dir",
        "Path to the root of all public files"
      ) do |project_root|
        project_root / "app" / "public"
      end

      c.store_ensured_path(
        "images_root_dir",
        "Path to the root of all images"
      ) do |public_root_dir|
        public_root_dir / "static" / "images"
      end

      c.store_ensured_path(
        "css_bundle_output_dir",
        "Path where bundled CSS is written for use in web pages"
      ) do |public_root_dir|
        public_root_dir / "css"
      end

      c.store_ensured_path(
        "js_bundle_output_dir",
        "Path where bundled JS is written for use in web pages"
      ) do |public_root_dir|
        public_root_dir / "js"
      end

      c.store(
        "database_url",
        String,
        "URL to the primary database - generally avoid this and use sequel_db_handle"
      ) do
        ENV.fetch("DATABASE_URL")
      end

      c.store(
        "sequel_db_handle",
        Object,
        "Handle to the database",
      ) do |database_url|
        Sequel.connect(database_url)
      end

      c.store_ensured_path(
        "app_src_dir",
        "Path to root of where all the app's source files are"
      ) do |project_root|
        project_root / "app" / "src"
      end

      c.store_ensured_path(
        "app_specs_dir",
        "Path to root of where all the app's specs/tests are"
      ) do |project_root|
        project_root / "specs"
      end

      c.store_ensured_path(
        "e2e_specs_dir",
        "Path to the root of all end-to-end tests"
      ) do |app_specs_dir|
        app_specs_dir / "e2e"
      end

      c.store_ensured_path(
        "js_specs_dir",
        "Path to root of where all JS-based specs/tests are",
      ) do |app_specs_dir|
        app_specs_dir / "front_end" / "js"
      end

      c.store_ensured_path(
        "front_end_src_dir",
        "Path to the root of the front end layer for the app"
      ) do |app_src_dir|
        app_src_dir / "front_end"
      end

      c.store_ensured_path(
        "components_src_dir",
        "Path to where components classes and templates are stored"
      ) do |front_end_src_dir|
        front_end_src_dir / "components"
      end

      c.store_ensured_path(
        "components_specs_dir",
        "Path to where tests of components classes are stored",
      ) do |app_specs_dir|
        app_specs_dir / "front_end" / "components"
      end

      c.store_ensured_path(
        "forms_src_dir",
        "Path to where form classes are stored"
      ) do |front_end_src_dir|
        front_end_src_dir / "forms"
      end

      c.store_ensured_path(
        "handlers_src_dir",
        "Path to where handlers are stored"
      ) do |front_end_src_dir|
        front_end_src_dir / "handlers"
      end

      c.store_ensured_path(
        "handlers_specs_dir",
        "Path to where tests of handler classes are stored",
      ) do |app_specs_dir|
        app_specs_dir / "front_end" / "handlers"
      end

      c.store_ensured_path(
        "svgs_src_dir",
        "Path to where svgs are stored"
      ) do |front_end_src_dir|
        front_end_src_dir / "svgs"
      end

      c.store_ensured_path(
        "images_src_dir",
        "Path to where images are stored"
      ) do |front_end_src_dir|
        front_end_src_dir / "images"
      end

      c.store_required_path(
        "pages_src_dir",
        "Path to where page classes and templates are stored"
      ) do |front_end_src_dir|
        front_end_src_dir / "pages"
      end

      c.store_required_path(
        "pages_specs_dir",
        "Path to where tests of page classes are stored",
      ) do |app_specs_dir|
        app_specs_dir / "front_end" / "pages"
      end

      c.store_required_path(
        "layouts_src_dir",
        "Path to where layout classes and templates are stored"
      ) do |front_end_src_dir|
        front_end_src_dir / "layouts"
      end

      c.store_required_path(
        "js_src_dir",
        "Path to where JS files are",
      ) do |front_end_src_dir|
        front_end_src_dir / "js"
      end

      c.store_ensured_path(
        "back_end_src_dir",
        "Path to the root of the back end layer for the app"
      ) do |app_src_dir|
        app_src_dir / "back_end"
      end

      c.store_ensured_path(
        "data_models_src_dir",
        "Path to the root of all data modeling",
      ) do |back_end_src_dir|
        back_end_src_dir / "data_models"
      end

      c.store_ensured_path(
        "migrations_dir",
        "Path to the DB migrations",
      ) do |data_models_src_dir|
        data_models_src_dir / "migrations"
      end

      c.store_ensured_path(
        "db_seeds_dir",
        "Path to the seed data for the DB",
      ) do |data_models_src_dir|
        data_models_src_dir / "seed"
      end

      c.store_ensured_path(
        "config_dir",
        "Path to where configuration files are stores"
      ) do |project_root|
        project_root / "app" / "config"
      end

      c.store_ensured_path(
        "i18n_locales_dir",
        "Path to where I18N locale files are stored"
      ) do |config_dir|
        config_dir / "i18n"
      end

      c.store(
        "asset_metadata_file",
        Pathname,
        "Path to the asset metadata file, used to manage hashed asset names"
      ) do |config_dir|
        config_dir / "asset_metadata.json"
      end


      c.store(
        "layout_locator",
        "Brut::FrontEnd::Component::TemplateLocator",
        "Object to use to locate templates for layouts"
      ) do |layouts_src_dir,project_env,brut_internal_dir|
        paths = if project_env.development?
                  [ layouts_src_dir, brut_internal_dir / "lib" / "brut" / "front_end" / "layouts" ]
                else
                  layouts_src_dir
                end
        Brut::FrontEnd::Component::TemplateLocator.new(paths: paths,
                                                       extension: "html.erb")
      end

      c.store_required_path(
        "brut_internal_dir",
        "Location to where the Brut gem is installed."
      ) do
        (Pathname(__FILE__).dirname / ".." / ".." / "..").expand_path
      end

      c.store(
        "page_locator",
        "Brut::FrontEnd::Component::TemplateLocator",
        "Object to use to locate templates for pages"
      ) do |pages_src_dir,project_env,brut_internal_dir|
        paths = if project_env.development?
                  [ pages_src_dir, brut_internal_dir / "lib" / "brut" / "front_end" / "pages" ]
                else
                  pages_src_dir
                end
        Brut::FrontEnd::Component::TemplateLocator.new(paths: paths,
                                                       extension: "html.erb")
      end

      c.store(
        "component_locator",
        "Brut::FrontEnd::Component::TemplateLocator",
        "Object to use to locate templates for components"
      ) do |components_src_dir, pages_src_dir|
        Brut::FrontEnd::Component::TemplateLocator.new(paths: [ components_src_dir, pages_src_dir ],
                                                       extension: "html.erb")
      end

      c.store(
        "svg_locator",
        "Brut::FrontEnd::Component::TemplateLocator",
        "Object to use to locate SVGs"
      ) do |svgs_src_dir|
        Brut::FrontEnd::Component::TemplateLocator.new(paths: svgs_src_dir,
                                                       extension: "svg")
      end

      c.store(
        "asset_path_resolver",
        "Brut::FrontEnd::Component::AssetPathResolver",
        "Object to use to resolve logical asset paths to actual asset paths"
      ) do |asset_metadata_file|
        Brut::FrontEnd::Component::AssetPathResolver.new(metadata_file: asset_metadata_file)
      end

      c.store(
        "routing",
        "Brut::FrontEnd::Routing",
        "Routing for all registered routes of this app",
        Brut::FrontEnd::Routing.new
      )

      c.store(
        "instrumentation",
        Brut::Instrumentation::Basic,
        "Interface for recording instrumentable events and subscribing to them",
      ) do |project_env|
        if project_env.production?
          Brut::Instrumentation::Basic.new
        else
          Brut::Instrumentation::Basic::TypeChecking.new
        end
      end

      # App can override

      c.store(
        "external_id_prefix",
        String,
        "String to use as a prefix for external ids in tables using the external_id feature. Nil means the feature is disabled",
        nil,
        allow_app_override: true,
        allow_nil: true,
      )

      c.store(
        "debug_zeitwerk?",
        :boolean,
        "If true, Zeitwerk's loading will be logged for debugging purposes. Do not enable this in production",
        false,
        allow_app_override: true,
      )

      c.store(
        "session_class",
        Class,
        "Class to use when wrapping the Rack session",
        Brut::FrontEnd::Session,
        allow_app_override: true,
      )

      c.store(
        "flash_class",
        Class,
        "Class to use to represent the Flash",
        Brut::FrontEnd::Flash,
        allow_app_override: true,
      )

      c.store(
        "semantic_logger_appenders",
        { Hash => "if only one appender is needed", Array => "to configure multiple appenders" },
        "List of appenders to be configured for SemanticLogger",
        allow_app_override: true
      ) do |project_env,log_dir|
        appenders = if project_env.development?
                      [
                        { formatter: :color, io: $stdout },
                        { file_name: (log_dir / "development.log").to_s },
                      ]
                    end
        if appenders.nil?
          appenders = { file_name: (log_dir / "#{project_env}.log").to_s }
        end
        if appenders.nil?
          appenders = { io: $stdout }
        end
        appenders
      end

      c.store(
        "eager_load_classes?",
        :boolean,
        "If true, classes are eagerly loaded upon startup",
        true,
        allow_app_override: true
      )

      c.store(
        "auto_reload_classes?",
        :boolean,
        "If true, classes are reloaded with each request. Useful only really for development",
        allow_app_override: true
      ) do |project_env|
        no_reload_in_dev = ENV["BRUT_NO_RELOAD_IN_DEV"] == "true"
        if project_env.development?
          !no_reload_in_dev
        else
          false
        end
      end

      c.store(
        "log_level",
        String,
        "Log level to control how much logging is happening",
        allow_app_override: true,
      ) do
        ENV["LOG_LEVEL"] || "debug"
      end

      c.store(
        "csp_class",
        Class,
        "Route Hook to use for setting the Content-Security-Policy header",
        allow_app_override: true,
        allow_nil: true,
      ) do |project_env|
        if project_env.development?
          Brut::FrontEnd::RouteHooks::CSPNoInlineScripts
        else
          Brut::FrontEnd::RouteHooks::CSPNoInlineStylesOrScripts
        end
      end

      c.store(
        "csp_reporting_class",
        Class,
        "Route Hook to use for setting the Content-Security-Policy-Report-Only header",
        Brut::FrontEnd::RouteHooks::CSPNoInlineStylesOrScripts::ReportOnly,
        allow_app_override: true,
        allow_nil: true,
      )
    end
  end
end
