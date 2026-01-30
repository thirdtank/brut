# Handles the configuration and startup process for your Brut-powered
# app and anything that needs its configuration, such as a CLI.
#
# This class models three phases:
#
# 1. *Initialized* - Ruby is running, but no Brut configuration has happened.
#
#    ```ruby
#    bootstrap = Bootstrap.new
#    ```
# 2. *Configured* - Brut's static configuration is set up.
#    See `Brut::Framework::MCP.initialize`.
#
#    ```ruby
#    configured = bootstrap.configure_only!
#    ```
#
# 3. *Bootstrapped* - Everything is set up and configured, services
#    have been connected-to and the app is generally ready to receive
#    requests or have its logic executed.
# 
#    ```ruby
#    booted = configured.bootstrap!
#    ```
class Bootstrap

  def configure_only!
    require "bundler"

    Bundler.require(:default, ENV.fetch("RACK_ENV").to_sym)

    require "brut"
    require "pathname"

    Brut.container.store_required_path(
      "project_root",
      "Root of the entire project's source code checkout",
      (Pathname(__dir__) / "..").expand_path)


    $: << File.join(Brut.container.project_root,"app","src")

    require "app"

    @mcp = Brut::Framework::MCP.new(app_klass: ::App)
    @app = @mcp.app
    self
  end

  attr_reader :rack_app, :app

  # @return [Bootstrap::ConfiguredBootstrap] that contains
  #         the {Brut::Framework::App} and {Brut::Framework::MCP}.
  def bootstrap!
    self.configure_only!
    @mcp.boot!
    @rack_app = @mcp.sinatra_app.new
    self
  end

end
