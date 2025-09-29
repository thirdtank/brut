# Adds Sidekiq to a Brut app
class MKBrut::Segments::Sidekiq < MKBrut::Base
  def self.friendly_name = "Use Sidekiq to Run Background Jobs"
  def initialize(project_root:, templates_dir:)
    @project_root  = project_root
    @templates_dir = templates_dir / "segments" / "Sidekiq"
  end

  def add!
    operations = copy_files(@templates_dir, @project_root) + 
                 other_operations

    operations.each do |operation|
      operation.call
    end
  end

  def <=>(other)
    if self.class == other.class
      0
    elsif other.class == MKBrut::Segments::Heroku
      # If both herkou and sidekiq segments are activated, we want to do heroku first,
      # since Sidekiq will need to modify it.
      1
    else
      -1
    end
  end

  def other_operations
    [
      MKBrut::Ops::AppendToFile.new(
        file: @project_root / "docker-compose.dx.yml",
        content: %{
  redis:
    # Change the value to what you are using in production.
    # If you are using actual Redis, change that here.
    image: valkey/valkey:8.1
},
      ),
      MKBrut::Ops::AppendToFile.new(
        file: @project_root / "Procfile.development",
        content: "sidekiq: bin/run sidekiq\n"
      ),
      MKBrut::Ops::AppendToFile.new(
        file: @project_root / "Procfile.test",
        content: "sidekiq: bin/run sidekiq\n"
      ),
      MKBrut::Ops::AppendToFile.new(
        file: @project_root / "Gemfile",
        content: "# Sidekiq is used for background jobs\ngem \"sidekiq\"\n"
      ),
      MKBrut::Ops::AppendToFile.new(
        file: @project_root / ".env.development",
        content: %{
# URL of the Redis/ValKey to use for Sidekiq
SIDEKIQ_REDIS_URL=redis://redis:6379/1
# Tells Sidekiq which ENV var to use for the Redis/ValKey URL
REDIS_PROVIDER=SIDEKIQ_REDIS_URL
# Username for basic auth into the Sidekiq Admin UI
SIDEKIQ_BASIC_AUTH_USER=sidekiq
# Passsword for basic auth into the Sidekiq Admin UI
SIDEKIQ_BASIC_AUTH_PASSWORD=password
}
      ),
      MKBrut::Ops::AppendToFile.new(
        file: @project_root / ".env.test",
        content: %{
SIDEKIQ_REDIS_URL=redis://redis:6379/2
REDIS_PROVIDER=SIDEKIQ_REDIS_URL
SIDEKIQ_BASIC_AUTH_USER=sidekiq-test
SIDEKIQ_BASIC_AUTH_PASSWORD=password
}
      ),
      MKBrut::Ops::InsertIntoFile.new(
        file: @project_root / "bin" / "test-server",
        before_line: "wait",
        content: "bin/run sidekiq &\n",
      ),
      MKBrut::Ops::InsertIntoFile.new(
        file: @project_root / "bin" / "setup",
        before_line: "  log \"Installing rspec binstubs\"",
        content: %{log "Installing sidekiq binstubs"
  system! "bundle binstub sidekiq"
}
      ),
      MKBrut::Ops::InsertIntoFile.new(
        file: @project_root / "specs" / "spec_helper.rb",
        before_line: "require \"brut/spec_support\"",
        content: "require \"sidekiq/testing\""
      ),
      MKBrut::Ops::InsertIntoFile.new(
        file: @project_root / "config.ru",
        before_line: "bootstrap = Bootstrap.new.bootstrap!",
        content: "require \"sidekiq/web\"\n"
      ),
      MKBrut::Ops::InsertIntoFile.new(
        file: @project_root / "config.ru",
        before_line: "  run bootstrap.rack_app",
        content: %{
  map "/sidekiq" do
    use Rack::Auth::Basic, "Sidekiq" do |username, password|
      [username, password] == [ENV.fetch("SIDEKIQ_BASIC_AUTH_USER"), ENV.fetch("SIDEKIQ_BASIC_AUTH_PASSWORD")]
    end
    run Sidekiq::Web.new
  end
}
      ),
      MKBrut::Ops::InsertCodeInMethod.new(
        file: @project_root / "app" / "src" / "app.rb",
        class_name: "App",
        method_name: "initialize",
        code: "@sidekiq_segment = SidekiqSegment.new",
      ),
      MKBrut::Ops::InsertCodeInMethod.new(
        file: @project_root / "app" / "src" / "app.rb",
        class_name: "App",
        method_name: "boot!",
        code: "@sidekiq_segment.boot!"
      ),
      MKBrut::Ops::InsertCodeInMethod.new(
        file: project_root / "deploy" / "heroku_config.rb",
        class_name: "HerokuConfig",
        method_name: "additional_images",
        class_method: true,
        ignore_if_file_not_found: true,
        code: %{
{
  "sidekiq" => {
    cmd: "bin/run sidekiq",
  }
}
        },
        where: :end
      ),
    ]
  end
end
