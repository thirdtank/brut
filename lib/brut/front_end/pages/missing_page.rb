# Used in development when a route has been mapped, but no class exists for the page. This
# renders a hopefully helpful message in the browser to allow the developer to know what 
# next steps to take.
class Brut::FrontEnd::Pages::MissingPage < Brut::FrontEnd::Page

  attr_reader :class_name,
              :path_template,
              :class_file,
              :scaffold_command,
              :types_of_files_created

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
    elsif route.class == Brut::FrontEnd::Routing::MissingPath
      @scaffold_command       = "handler"
      @types_of_files_created = "handler class, and test"
    else
      nil
    end
  end

  def layout = "_internal"
  def template_name = "_missing_page"
end
