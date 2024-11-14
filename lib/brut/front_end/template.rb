require "temple"

module Brut::FrontEnd::Templates
  autoload(:HTMLSafeString,"brut/front_end/templates/html_safe_string")
  autoload(:ERBParser,"brut/front_end/templates/erb_parser")
  autoload(:EscapableFilter,"brut/front_end/templates/escapable_filter")
  autoload(:BlockFilter,"brut/front_end/templates/block_filter")
  autoload(:ERBEngine,"brut/front_end/templates/erb_engine")
end

# Handles rendering HTML templates
class Brut::FrontEnd::Template

  TempleTemplate = Temple::Templates::Tilt(Brut::FrontEnd::Templates::ERBEngine,
                                           register_as: "html.erb")

  # Wraps a string that is deemed safe to insert into
  # HTML without escaping it.  This allows stuff like
  # <%= component(SomeComponent) %> to work without
  # having to remember to <%== all the time.
  def initialize(template_file_path)
    @tilt_template = Tilt.new(template_file_path)
  end

  def render_template(...)
    @tilt_template.render(...)
  end

  def self.escape_html(string)
    Brut::FrontEnd::Templates::EscapableFilter.escape_html(string)
  end
end
