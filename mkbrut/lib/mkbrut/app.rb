require "fileutils"
require "erb"
require "ostruct"

module MKBrut
  class App
    def initialize(current_dir:, app_options:, out:, err:)
      @out = out
      @app_options = app_options

      @out.puts "Creating app with these options:\n"
      @out.puts "App name:      #{app_options.app_name}"
      @out.puts "App ID:        #{app_options.app_id}"
      @out.puts "Prefix:        #{app_options.prefix}"
      @out.puts "Organization:  #{app_options.organization}"
      @out.puts "Include demo?  #{app_options.demo}\n"

      if app_options.dry_run?
        @out.puts "Dry Run"
        MKBrut::Ops::BaseOp.dry_run = true
      end

      templates_dir = Pathname(
        Gem::Specification.find_by_name("mkbrut").gem_dir
      ) / "templates"

      @base = MKBrut::Base.new(
        app_options:,
        current_dir:,
        templates_dir:
      )
      @segments = [
        MKBrut::Segments::BareBones.new(
          app_options:,
          current_dir:,
          templates_dir:,
        ),
      ]
      if app_options.demo?
        @segments << MKBrut::Segments::Demo.new(
          app_options:,
          current_dir:,
          templates_dir:
        )
      end
      app_options.segments.each do |segment|
        case segment
        when "heroku"
          @segments << MKBrut::Segments::Heroku.new(
            project_root: @base.project_root,
            templates_dir:
          )
        when "sidekiq"
          @segments << MKBrut::Segments::Sidekiq.new(
            project_root: @base.project_root,
            templates_dir:
          )
        else
          raise "Segment #{segment} is not supported"
        end
      end
      @segments.sort!
    end

    def create!
      @out.puts "Creating Base app"
      @base.create!
      @segments.each do |segment|
        @out.puts "Creating segment: #{segment.class.friendly_name}"
        segment.add!
      end
      @out.puts "#{@app_options.app_name} was created\n\n"
      @out.puts "Time to get building:"
      @out.puts "1. cd #{@app_options.app_name}"
      @out.puts "2. dx/build"
      @out.puts "3. dx/start"
      @out.puts "4. [ in another terminal ] dx/exec bash"
      @out.puts "5. [ inside the Docker container ] bin/setup"
      @out.puts "6. [ inside the Docker container ] bin/dev"
      @out.puts "7. Visit http://localhost:6502 in your browser"
      @out.puts "8. [ inside the Docker container ] bin/setup help # to see more commands"
    end
  end
end
