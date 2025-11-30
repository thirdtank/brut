require "pathname"
require "securerandom"
# Constructs the base of any Brut app.
class Brut::CLI::Apps::New::Base
  include Brut::CLI::Apps::New

  class ErbBinding < Brut::CLI::Apps::New::ErbBindingDelegate
    def session_secret = SecureRandom.hex(64)
  end

  attr_reader :project_root
  def initialize(app_name:, options:, versions:, current_dir:, templates_dir:)
    @project_root  = current_dir / app_name
    @templates_dir = templates_dir / "Base"
    @erb_binding   = ErbBinding.new(options:, app_name:, versions:)
  end

  def output_post_add_messaging(stdout:)
  end

  def create!
    if @project_root.exist?
      raise "Project root #{@project_root} already exists"
    end
    operations = [ Ops::Mkdir.new(@project_root) ]           + 
                   copy_files(@templates_dir, @project_root)

    operations.each do |operation|
      operation.call
    end
  end

private

  def filenames_to_always_skip = [ "README.md", "mkicons.sh" ]

  def copy_files(source_dir, destination_root)
    operations = []
    Dir.glob("#{source_dir}/*", flags: File::FNM_DOTMATCH).each do |template_file|
      template_file = Pathname(template_file)
      if [ ".", ".." ].include?(template_file.basename.to_s)
        next
      end
      if template_file.directory?
        operations << Ops::Mkdir.new(destination_root / template_file.basename)
        operations += copy_files(template_file, destination_root / template_file.basename)
      elsif template_file.extname == ".erb"
        operations << Ops::RenderTemplate.new(
          template_file,
          destination_root:,
          erb_binding: @erb_binding
        )
      elsif filenames_to_always_skip.include?(template_file.basename.to_s)
        operations << Ops::SkipFile.new(template_file)
      else
        operations << Ops::CopyFile.new(template_file, destination_root:)
      end
    end
    operations
  end
end
