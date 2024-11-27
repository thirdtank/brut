class Brut::FrontEnd::Pages::Missing < Brut::FrontEnd::Page
  attr_reader :class_name, :path_template, :class_file
  def initialize(route:)
    @class_name = route.exception.class_name_path.join("::")
    @path_template = route.path_template
    parts = route.exception.class_name_path.map { |part|
      RichString.new(part).underscorized.to_s
    }
    last_part = parts[-1]
    parts[-1] = last_part + ".rb"
    @class_file = parts.reduce(Brut.container.pages_src_dir.relative_path_from(Brut.container.project_root)) { |acc,part|
      acc / RichString.new(part).underscorized.to_s
    }
  end

  def layout = "_internal"
  def template_name = "_missing"
end
