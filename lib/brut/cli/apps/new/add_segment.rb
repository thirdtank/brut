require "fileutils"
require "erb"

class Brut::CLI::Apps::New
  class AddSegment
    def initialize(current_dir:, add_segment_options:, out:, err:)
      @out = out
      @add_segment_options = add_segment_options

      @out.puts "Adding #{@add_segment_options.segment_name} to this app"

      if @add_segment_options.dry_run?
        @out.puts "Dry Run"
        Brut::CLI::Apps::New::Ops::BaseOp.dry_run = true
      end

      templates_dir = Pathname(
        Gem::Specification.find_by_name("brut").gem_dir
      ) / "templates"

      @segment = if @add_segment_options.segment_name == "sidekiq"
                   Brut::CLI::Apps::New::Segments::Sidekiq.new(
                     project_root: add_segment_options.project_root,
                     templates_dir:
                   )
                 elsif @add_segment_options.segment_name == "heroku"
                   Brut::CLI::Apps::New::Segments::Heroku.new(
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
