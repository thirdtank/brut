class Brut::FrontEnd::Pages::MissingPage < Brut::FrontEnd::Page
  attr_reader :class_name, :path_template, :class_file, :scaffold_command, :types_of_files_created
  def initialize(route:)
    @class_name = route.exception.class_name_path.join("::")
    @path_template = route.path_template
    parts = route.exception.class_name_path.map { |part|
      RichString.new(part).underscorized.to_s
    }
    last_part = parts[-1]
    parts[-1] = last_part + ".rb"
    if route.class == Brut::FrontEnd::Routing::MissingForm
      @scaffold_command       = "form"
      @types_of_files_created = "form class, handler class, and test"
    elsif route.class == Brut::FrontEnd::Routing::MissingPage
      @scaffold_command       = "page"
      @types_of_files_created = "page class, HTML template, and test"
    else
      nil
    end
  end

  def layout = "_internal"
  def template_name = "_missing_page"
end
