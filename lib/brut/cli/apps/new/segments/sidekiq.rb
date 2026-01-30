# Adds Sidekiq to a Brut app
class Brut::CLI::Apps::New::Segments::Sidekiq < Brut::CLI::Apps::New::Base

  def self.friendly_name = "Sidekiq for Background Jobs"
  def self.segment_name = "sidekiq"

  def initialize(project_root:, templates_dir:)
    @project_root  = project_root
    @templates_dir = templates_dir / "segments" / "Sidekiq"
  end

  def output_post_add_messaging(stdout:)
    stdout.puts ""
    stdout.puts "Sidekiq has now been set up for your app. The configuration used is"
    stdout.puts "a basic one, suitable for getting started, however you know own this"
    stdout.puts "configuration.  Most of it is in these files:"
    stdout.puts ""
    stdout.puts "    app/config/sidekiq.yml"
    stdout.puts "    app/src/back_end/segments/sidekiq_segment.rb"
    stdout.puts ""
    stdout.puts "You are encouraged to verify everything is set up as follows:"
    stdout.puts ""
    stdout.puts "1. Quit dx/start, and start it back up - this will downloaded and set up ValKey/Redis"
    stdout.puts "2. Re-run bin/setup. This will install needed gems and create binstubs"
    stdout.puts "3. Run the example integration test:"
    stdout.puts ""
    stdout.puts "   bin/test e2e specs/integration/sidekiq_works.spec.rb"
    stdout.puts ""
    stdout.puts "   This will use the actual Sidekiq server, so if it passes, you should"
    stdout.puts "   all set and can start creating jobs"
    stdout.puts ""
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
    elsif other.class == Brut::CLI::Apps::New::Segments::Heroku
      # If both herkou and sidekiq segments are activated, we want to do heroku first,
      # since Sidekiq will need to modify it.
      1
    else
      -1
    end
  end

  def other_operations
    [
      Brut::CLI::Apps::New::Ops::AppendToFile.new(
        file: @project_root / "docker-compose.dx.yml",
        content: %{
  redis:
    # Change the value to what you are using in production.
    # If you are using actual Redis, change that here.
    image: valkey/valkey:8.1
},
      ),
      Brut::CLI::Apps::New::Ops::AppendToFile.new(
        file: @project_root / "Procfile.development",
        content: "sidekiq: bin/run sidekiq\n"
      ),
      Brut::CLI::Apps::New::Ops::AppendToFile.new(
        file: @project_root / "Procfile.test",
        content: "sidekiq: bin/run sidekiq\n"
      ),
      Brut::CLI::Apps::New::Ops::AppendToFile.new(
        file: @project_root / "Gemfile",
        content: "# Sidekiq is used for background jobs\ngem \"sidekiq\"\n"
      ),
      Brut::CLI::Apps::New::Ops::AppendToFile.new(
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
      Brut::CLI::Apps::New::Ops::AppendToFile.new(
        file: @project_root / ".env.test",
        content: %{
SIDEKIQ_REDIS_URL=redis://redis:6379/2
REDIS_PROVIDER=SIDEKIQ_REDIS_URL
SIDEKIQ_BASIC_AUTH_USER=sidekiq-test
SIDEKIQ_BASIC_AUTH_PASSWORD=password
}
      ),
      Brut::CLI::Apps::New::Ops::InsertIntoFile.new(
        file: @project_root / "bin" / "test-server",
        before_line: "wait",
        content: "bin/run sidekiq &\n",
      ),
      Brut::CLI::Apps::New::Ops::InsertIntoFile.new(
        file: @project_root / "bin" / "setup",
        before_line: "      step \"Installing rspec binstubs\",   exec: \"bundle binstub rspec-core\"",
        content:     "      step \"Installing sidekiq binstubs\", exec: \"bundle binstub sidekiq\""   
      ),
      Brut::CLI::Apps::New::Ops::InsertIntoFile.new(
        file: @project_root / "specs" / "spec_helper.rb",
        before_line: "require \"brut/spec_support\"",
        content: "require \"sidekiq/testing\""
      ),
      Brut::CLI::Apps::New::Ops::InsertIntoFile.new(
        file: @project_root / "config.ru",
        before_line: "bootstrap = Bootstrap.new.bootstrap!",
        content: "require \"sidekiq/web\"\n"
      ),
      Brut::CLI::Apps::New::Ops::InsertIntoFile.new(
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
      Brut::CLI::Apps::New::Ops::InsertCodeInMethod.new(
        file: @project_root / "app" / "src" / "app.rb",
        class_name: "App",
        method_name: "initialize",
        code: "@sidekiq_segment = SidekiqSegment.new",
      ),
      Brut::CLI::Apps::New::Ops::InsertCodeInMethod.new(
        file: @project_root / "app" / "src" / "app.rb",
        class_name: "App",
        method_name: "boot!",
        code: "@sidekiq_segment.boot!"
      ),
      Brut::CLI::Apps::New::Ops::InsertCodeInMethod.new(
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
