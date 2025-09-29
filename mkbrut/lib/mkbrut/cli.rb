require "optparse"
require "pathname"

module MKBrut
  class CLI
    def initialize(args:, out: $stdout, err: $stderr)
      @args    = args
      @out     = out
      @err     = err
    end

    def run

      command = if @args.first == "add-segment"
                  @args.shift
                  :add_segment
                elsif @args.first == "new-app" || @args.first == "new"
                  @args.shift
                  :new_app
                else
                  :new_app
                end

      if command == :new_app
        app_options = parse_options(@args, MKBrut::Versions.new)
        new_app = MKBrut::App.new(
          current_dir: Pathname.pwd.expand_path,
          app_options:,
          out: PrefixedIO.new(@out, "mkbrut"),
          err: @err
        )
        new_app.create!
      elsif command == :add_segment
        add_segment_options = parse_add_segment_options(@args, MKBrut::Versions.new)
        add_segment = MKBrut::AddSegment.new(
          current_dir: add_segment_options.project_root,
          add_segment_options:,
          out: PrefixedIO.new(@out, "mkbrut"),
          err: @err
        )
        add_segment.add!
        @out.puts ""
        @out.puts "Sidekiq has now been set up for your app. The configuration used is"
        @out.puts "a basic one, suitable for getting started, however you know own this"
        @out.puts "configuration.  Most of it is in these files:"
        @out.puts ""
        @out.puts "    app/config/sidekiq.yml"
        @out.puts "    app/src/back_end/segments/sidekiq_segment.rb"
        @out.puts ""
        @out.puts "You are encouraged to verify everything is set up as follows:"
        @out.puts ""
        @out.puts "1. Quit dx/start, and start it back up - this will downloaded and set up ValKey/Redis"
        @out.puts "2. Re-run bin/setup. This will install needed gems and create binstubs"
        @out.puts "3. Run the example integration test:"
        @out.puts ""
        @out.puts "   bin/test e2e specs/integration/sidekiq_works.spec.rb"
        @out.puts ""
        @out.puts "   This will use the actual Sidekiq server, so if it passes, you should"
        @out.puts "   all set and can start creating jobs"
        @out.puts ""
      else
        raise "Unknown command #{command}"
      end
      0
    rescue => e
      @err.puts "Error: #{e.message}"
      if ENV["BRUT_CLI_RAISE_ON_ERROR"] == "true"
        raise
      end
      1
    end

    def show_help(versions)
      @out.puts @option_parser
      @out.puts
      @out.puts "ARGUMENTS"
      @out.puts
      @out.puts "    app-name - name for your app, which will be the folder where your app's files are created"
      @out.puts
      @out.puts "ENVIRONMENT VARIABLES"
      @out.puts
      @out.puts "  BRUT_CLI_RAISE_ON_ERROR - if set to 'true', any error will raise an exception instead of printing to stderr"
      @out.puts
    end

  private


    def parse_options(args, versions)
      options = {}
      @option_parser = OptionParser.new do |opts|
        opts.accept(MKBrut::Prefix) do |prefix|
          MKBrut::Prefix.new(prefix)
        end
        opts.accept(MKBrut::AppId) do |prefix|
          MKBrut::AppId.new(prefix)
        end
        opts.accept(MKBrut::Organization) do |prefix|
          MKBrut::Organization.new(prefix)
        end
        opts.banner = [
          "Usage: mkbrut [options] app-name",
          "",
          "    Creates a new Brut-powered app",
          "",
          "VERSION",
          "",
          "    #{MKBrut::VERSION}",
          "",
          "OPTIONS",
          "",
        ].join("\n")

        opts.on("-a", "--app-id=ID", MKBrut::AppId,
                "App identifier, which must be able to be used as a hostname or other Internet identifier. Derived from your app name, if omitted")

        opts.on("-o", "--organization=ORG",MKBrut::Organization,
                "Organization name, e.g. what you'd use for GitHub. Defaults to the app-id value")

        opts.on("-e", "--prefix=PREFIX", MKBrut::Prefix,
                "Two-character prefix for external IDs and autonomous custom elements. Derived from your app-id, if omitted.")

        opts.on("--dry-run", "Only show what would happen, don't actually do anything")
        opts.on("--[no-]demo", "Include, or not, additional files that demonstrate Brut's features (default is true for now")
        {
          "sidekiq" => "Use Sidekiq for background jobs",
          "heroku" => "Use Heroku for container-based deployment",
        }.each do |segment,description|
          opts.on("--segment-#{segment}", description)
        end
        opts.on("-h", "--help", "Show this help message") do
          show_help(versions)
          exit
        end
      end

      @option_parser.parse!(args, into: options)
      if !options.key?(:demo)
        options[:demo] = true
      end

      options[:app_name] = MKBrut::AppName.new(args.first)
      options[:app_id] = options[:'app-id']
      options[:dry_run] = !!options[:'dry-run']
      MKBrut::AppOptions.new(**options, versions:)
    end

    def parse_add_segment_options(args, versions)
      options = {}
      @option_parser = OptionParser.new do |opts|
        opts.banner = [
          "Usage: mkbrut add-segment [options] segment-name",
          "",
          "    Adds a segment to an existing Brut-powered app",
          "",
          "VERSION",
          "",
          "    #{MKBrut::VERSION}",
          "",
          "OPTIONS",
          "",
        ].join("\n")

        opts.on("-r PROJECT_ROOT_DIR", "--project-root=PROJECT_ROOT_DIR", "Path to the root of the existing Brut app (defaults to current directory)")
        opts.on("--dry-run", "Only show what would happen, don't actually do anything")
        opts.on("--[no-]demo", "Include, or not, additional files that demonstrate Brut's features (default is true for now")
        opts.on("-h", "--help", "Show this help message") do
          @out.puts @option_parser
          @out.puts
          @out.puts "ARGUMENTS"
          @out.puts
          @out.puts "    segment-name - name of the segment to add.  Known values:"
          @out.puts "                   sidekiq - add support for Sidekiq"
          @out.puts "                   heroku  - add support for Heroku container-based deployment"
          @out.puts
          @out.puts "ENVIRONMENT VARIABLES"
          @out.puts
          @out.puts "  BRUT_CLI_RAISE_ON_ERROR - if set to 'true', any error will raise an exception instead of printing to stderr"
          @out.puts
          exit
        end
      end

      @option_parser.parse!(args, into: options)
      options[:project_root] = Pathname.new(options[:'project-root'] || ".").expand_path
      MKBrut::AddSegmentOptions.new(segment_name: @args[0], **options, versions:)
    end
  end
end 
