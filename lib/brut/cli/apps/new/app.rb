require "fileutils"
require "erb"
require "ostruct"
require "lipgloss"

class Brut::CLI::Apps::New::App < Brut::CLI::Commands::BaseCommand
  def name = "new"
  def description = "Create a Brut App or modify an existing one with new segments"
  def args_description = "app_name"

  LOGO_WIDE = %{
#################                                     ####      #################      ################
##################                                    ####      ##################     #################
#####        #####                                    ####      #####        ######    #####       #####
#####        #####    ####  ####  ####       ####  ##########   #####         #####    #####       #####
#####      ######     ##########  ####       ####  ##########   #####        #####     #####     ######
################      ######      ####       ####     ####      #################      ################
#####       ######    #####       ####       ####     ####      #################      #####      ######
#####         #####   ####        ####       ####     ####      #####        #####     #####        #####
#####         #####   ####        ####       ####     ####      #####        #####     #####        #####
#####        ######   ####        #####     #####     ####      #####         ####     #####       ######
##################    ####         ##############     #######   #####         ####     #################
###############       ####          #######  ####      ######   #####         #####    ##############
  }.strip
  LOGO_NARROW = %{
#################                                     ####
##################                                    ####
#####        #####                                    ####
#####        #####    ####  ####  ####       ####  ##########
#####      ######     ##########  ####       ####  ##########
################      ######      ####       ####     ####
#####       ######    #####       ####       ####     ####
#####         #####   ####        ####       ####     ####
#####         #####   ####        ####       ####     ####
#####        ######   ####        #####     #####     ####
##################    ####         ##############     #######
###############       ####          #######  ####      ######
  }.strip

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
      "App identifier, which must be able to be used as a hostname or other Internet identifier. Derived from your app name, if omitted",
    ],
    [
      "--organization=ORG",
      Brut::CLI::Apps::New::Organization,
      "Organization name, e.g. what you'd use for GitHub. Defaults to the app-id value",
    ],
    [
      "--[no-]interactive",
      "Set if you want to be prompted before the app is actually created",
    ],
    [
      "--prefix=PREFIX",
      Brut::CLI::Apps::New::Prefix,
      "Two-character prefix for external IDs and autonomous custom elements. Derived from your app-id, if omitted.",
    ],
    [ 
      "--segments=SEGMENTS",
      Array,
      "Comma-delimited list of segment names to add additional behavior to your new app. Current values: heroku, sidekiq, demo",
    ],
    [ 
      "--dry-run",
      "Only show what would happen, don't actually do anything",
    ],
    [
      "--[no-]demo",
      "Include, or not, additional files that demonstrate Brut's features (default is true for now)",
    ],
  ]

  def run

    app_name = argv[0]

    if !app_name
      error "app_name is required"
      return 1
    end

    if terminal.cols >= LOGO_WIDE.lines[0].length
      puts theme.title.render("WELCOME TO")
      puts
      puts theme.title.render(LOGO_WIDE)
    elsif terminal.cols >= LOGO_NARROW.lines[0].length
      puts theme.title.render("WELCOME TO")
      puts
      puts theme.title.render(LOGO_NARROW)
    else
      puts theme.title.render("WELCOME TO BRUT")
    end

    options.set_default(:app_id, Brut::CLI::Apps::New::AppId.from_app_name(app_name))
    options.set_default(:prefix, Brut::CLI::Apps::New::Prefix.from_app_id(options.app_id))
    options.set_default(:organization, Brut::CLI::Apps::New::Prefix.from_app_id(options.app_id))
    options.set_default(:demo, true)
    options.set_default(:dir,Pathname.pwd)
    options.set_default(:interactive, true)

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

    info "Creating a new Brut app with these options:"
    rows = [
      ["App Name",  app_name],
      ["Path to New App", current_dir / app_name],
      ["App Id", options.app_id ],
      ["Prefix", options.prefix ],
      ["Organization", options.organization ],
      ["Segments", segments.map(&:class).map(&:segment_name).join(", ") ],
    ]
    rows.each do |(attr,val)|
      info "  #{attr}: #{val}"
    end
    if options.interactive?
      puts
      puts theme.subheader.render("Options for your new app:")
      table = Lipgloss::Table.new.headers(["Attribute", "Value"]).
        rows(rows).
        border(:rounded).
        style_func(rows: rows.size, columns: 2) do |row,column|
          if row == Lipgloss::Table::HEADER_ROW
            if column == 0
              Lipgloss::Style.new.inherit(theme.header).align_horizontal(:right).padding_right(1).padding_left(1)
            else
              Lipgloss::Style.new.inherit(theme.header).align_horizontal(:left).padding_right(1).padding_left(1)
            end
          elsif column == 0
            Lipgloss::Style.new.inherit(theme.subheader).align_horizontal(:right).padding_right(1).padding_left(1)
          else
            Lipgloss::Style.new.inherit(theme.none).align_horizontal(:left).padding_right(1).padding_left(1)
          end
        end

      puts table.render

      puts "Proceed? (y/n): "
      answer = stdin.gets.strip.downcase
      if answer != "y"
        puts theme.warning.render("Aborting app creation")
        return 0
      end
    end

    if options.dry_run?
      info "Dry Run only"
      Brut::CLI::Apps::New::Ops::BaseOp.dry_run = true
    end

    info "Creating Base app"
    base.create!
    segments.each do |segment|
      info "Creating segment: #{segment.class.friendly_name}"
      segment.add!
    end

    puts
    print theme.header.render("Your app ")
    print theme.subheader.render(app_name)
    print theme.header.render(" was created - time to get building!")
    puts
    puts

    in_computer = Lipgloss::List.new.items(
      [
        theme.code.render("cd #{current_dir / app_name}"),
        theme.code.render("dx/build"),
        theme.code.render("dx/start"),
        "#{theme.weak.render("(in another terminal)")} #{theme.code.render('dx/exec bash')}",
      ]
    ).enumerator(:arabic).enumerator_style(theme.bullet(1))
    in_docker = Lipgloss::List.new.items(
      [
        theme.code.render("bin/setup"),
        theme.code.render("bin/dev"),
      ]
    ).enumerator(:arabic).enumerator_style(theme.bullet(1))
    list = Lipgloss::List.new.items([
      "On your computer:\n#{in_computer.render}",
      "Inside the Docker container:\n#{in_docker.render}",
      "Navigate to #{theme.url.render('http://localhost:6502')} to see your app",
      "Inside the Docker container, try #{theme.code.render('bin/setup')} help to find more commands",
    ]).enumerator(:arabic).
    enumerator_style(theme.bullet(0))
    puts list.render
    puts
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
        "Only show what would happen, don't actually do anything",
      ],
    ]

    def run
      options.set_default(:dir,Pathname.pwd)

      segment_name = argv[0]
      if !segment_name
        error "segment_name is required"
        return 1
      end
      if options.demo?
        segment_names << "demo"
      end

      project_root = options.dir.expand_path
      versions = Brut::CLI::Apps::New::Versions.new


      if options.dry_run?
        puts "Dry Run"
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
        error "'#{segment_name}' is not a segment. Allowed values: sidekiq, heroku"
        return 1
      end

      puts "Adding #{segment_name} to this app"
      segment.add!
      segment.output_post_add_messaging(stdout:)
      0
    end
  end
end
