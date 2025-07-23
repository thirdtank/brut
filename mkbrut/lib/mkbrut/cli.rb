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

      app_options = parse_options(@args, MKBrut::Versions.new)
      new_app = MKBrut::App.new(
        current_dir: Pathname.pwd.expand_path,
        app_options:,
        out: PrefixedIO.new(@out, "mkbrut"),
        err: @err
      )
      new_app.create!
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
      MKBrut::AppOptions.new(**options.merge(versions:))
    end

  end
end 
