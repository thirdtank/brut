require "fileutils"
require "erb"
require "ostruct"

class Brut::CLI::Apps::New::App < Brut::CLI::Commands::BaseCommand
  def name = "new"
  def description = "Create a Brut App or modify an existing one with new segments"
  def args_description = "app_name"

  def accepts = [
    Brut::CLI::Apps::New::Prefix,
    Brut::CLI::Apps::New::AppId,
    Brut::CLI::Apps::New::Organization,
    [ Pathname, ->(value) { Pathname(value) } ],
  ]

  def opts = [
    [
      "--dir=DIR",
      Pathname,
      "Path where you want your app created. Default is the current directory",
    ],
    [ 
      "--app-id=ID",
      Brut::CLI::Apps::New::AppId,
      "App identifier, which must be able to be used as a hostname or other Internet identifier. Derived from your app name, if omitted"
    ],
    [
      "--[no-]interactive",
      "Don't ask for user input, just assume default answers",
    ],
    [
      "--organization=ORG",
      Brut::CLI::Apps::New::Organization,
      "Organization name, e.g. what you'd use for GitHub. Defaults to the app-id value"
    ],

    [
      "--prefix=PREFIX",
      Brut::CLI::Apps::New::Prefix,
      "Two-character prefix for external IDs and autonomous custom elements. Derived from your app-id, if omitted."
    ],
    [ 
      "--segments=SEGMENTS",
      Array,
      "Comma-delimited list of segment names to add additional behavior to your new app. Current values: heroku, sidekiq, demo",
    ],
    [ 
      "--dry-run",
      "Only show what would happen, don't actually do anything"
    ],
    [
      "--[no-]demo",
      "Include, or not, additional files that demonstrate Brut's features (default is true for now)"
    ],
  ]

  def run

    app_name = argv[0]

    if !app_name
      stderr.puts "app_name is required"
      return 1
    end

    options.set_default(:app_id, Brut::CLI::Apps::New::AppId.from_app_name(app_name))
    options.set_default(:prefix, Brut::CLI::Apps::New::Prefix.from_app_id(options.app_id))
    options.set_default(:organization, Brut::CLI::Apps::New::Prefix.from_app_id(options.app_id))
    options.set_default(:demo, true)
    options.set_default(:interactive, true)
    options.set_default(:dir,Pathname.pwd)

    segment_names = Set.new(options.segments)
    if options.demo?
      segment_names << "demo"
    end

    current_dir = options.dir.expand_path
    versions = Brut::CLI::Apps::New::Versions.new

    templates_dir = Pathname(
      Gem::Specification.find_by_name("brut").gem_dir
    ) / "templates"

    base = Brut::CLI::Apps::New::Base.new(
      app_name:,
      options:,
      versions:,
      current_dir:,
      templates_dir:
    )
    segments = [
      Brut::CLI::Apps::New::Segments::BareBones.new(
        app_name:,
        options:,
        versions:,
        current_dir:,
        templates_dir:,
      ),
    ]
    if options.demo?
      segments << Brut::CLI::Apps::New::Segments::Demo.new(
        app_name:,
        options:,
        versions:,
        current_dir:,
        templates_dir:
      )
    end
    segment_names.each do |segment|
      case segment
      when "heroku"
        segments << Brut::CLI::Apps::New::Segments::Heroku.new(
          project_root: base.project_root,
          templates_dir:
        )
      when "sidekiq"
        segments << Brut::CLI::Apps::New::Segments::Sidekiq.new(
          project_root: base.project_root,
          templates_dir:
        )
      when "demo"
        # handled above
      else
        raise "Segment #{segment} is not supported"
      end
    end
    segments.sort!

    stdout.puts "Creating a new Brut app with these options:\n"
    stdout.puts "App Name        : #{app_name}"
    stdout.puts "Path to New App : #{current_dir / app_name}"
    stdout.puts "App Id          : #{options.app_id}"
    stdout.puts "Prefix          : #{options.prefix}"
    stdout.puts "Organization    : #{options.organization}"
    stdout.puts "Segments        : #{segments.map(&:class).map(&:segment_name).join(", ")}"
    stdout.puts

    if options.dry_run?
      stdout.puts "Dry Run only"
      Brut::CLI::Apps::New::Ops::BaseOp.dry_run = true
    end

    if options.interactive?
      stdout.puts "Proceed? (Y/N)"
      answer = stdin.gets
      if answer.downcase.strip.chomp != "y"
        stdout.puts "Aborting...."
        exit
      end
    end

    stdout.puts "Creating Base app"
    base.create!
    segments.each do |segment|
      stdout.puts "Creating segment: #{segment.class.friendly_name}"
      segment.add!
    end
    stdout.puts "#{options.app_name} was created\n\n"
    stdout.puts "Time to get building:"
    stdout.puts "1. cd #{current_dir / app_name}"
    stdout.puts "2. dx/build"
    stdout.puts "3. dx/start"
    stdout.puts "4. [ in another terminal ] dx/exec bash"
    stdout.puts "5. [ inside the Docker container ] bin/setup"
    stdout.puts "6. [ inside the Docker container ] bin/dev"
    stdout.puts "7. Visit http://localhost:6502 in your browser"
    stdout.puts "8. [ inside the Docker container ] bin/setup help # to see more commands"
  end

  class Segment < Brut::CLI::Commands::BaseCommand
    def description = "Add a segement to your app to provide additional pre-configured functionality"

    def args_description = "segment_name"
    
    def accepts = [
      [ Pathname, ->(value) { Pathname(value) } ],
    ]

    def opts = [
      [
        "--dir=DIR",
        Pathname,
        "Path to your app. Default is the current directory",
      ],
      [ 
        "--dry-run",
        "Only show what would happen, don't actually do anything"
      ],
    ]

    def run
      options.set_default(:dir,Pathname.pwd)

      segment_name = argv[0]
      if !segment_name
        stderr.puts "segment_name is required"
        return 1
      end
      if options.demo?
        segment_names << "demo"
      end

      project_root = options.dir.expand_path
      versions = Brut::CLI::Apps::New::Versions.new


      if options.dry_run?
        stdout.puts "Dry Run"
        Brut::CLI::Apps::New::Ops::BaseOp.dry_run = true
      end

      templates_dir = Pathname(
        Gem::Specification.find_by_name("brut").gem_dir
      ) / "templates"

      segment = if segment_name == "sidekiq"
                   Brut::CLI::Apps::New::Segments::Sidekiq.new(
                     project_root:,
                     templates_dir:
                   )
                 elsif segment_name == "heroku"
                   Brut::CLI::Apps::New::Segments::Heroku.new(
                     project_root:,
                     templates_dir:
                   )
                 end
      if !segment
        stderr.puts "'#{segment_name}' is not a segment. Allowed values: sidekiq, heroku"
        return 1
      end

      stdout.puts "Adding #{segment_name} to this app"
      segment.add!
      segment.output_post_add_messaging(stdout:)
      0
    end
  end
end
