require "fileutils"
require "erb"

module MKBrut
  class AddSegment
    def initialize(current_dir:, add_segment_options:, out:, err:)
      @out = out
      @add_segment_options = add_segment_options

      @out.puts "Adding #{@add_segment_options.segment_name} to this app"

      if @add_segment_options.dry_run?
        @out.puts "Dry Run"
        MKBrut::Ops::BaseOp.dry_run = true
      end

      templates_dir = Pathname(
        Gem::Specification.find_by_name("mkbrut").gem_dir
      ) / "templates"

      @segment = if @add_segment_options.segment_name == "sidekiq"
                   MKBrut::Segments::Sidekiq.new(
                     project_root: add_segment_options.project_root,
                     templates_dir:
                   )
                 elsif @add_segment_options.segment_name == "heroku"
                   MKBrut::Segments::Heroku.new(
                     project_root: add_segment_options.project_root,
                     templates_dir:
                   )
                 end
    end

    def add!
      @segment.add!
    end
  end
end
