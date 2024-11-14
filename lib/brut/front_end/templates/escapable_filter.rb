# A temple filter that handles escaping HTML unless it's been wrapped in
# an HTMLSafeString.
class Brut::FrontEnd::Templates::EscapableFilter < Temple::Filters::Escapable
  using Brut::FrontEnd::Templates::HTMLSafeString::Refinement

  def initialize(opts = {})
    opts[:escape_code] ||= "::Brut::FrontEnd::Templates::EscapableFilter.escape_html((%s))"
    super(opts)
  end

  def self.escape_html(html)
    if html.kind_of?(Brut::FrontEnd::Templates::HTMLSafeString)
      html.string
    else
      Temple::Utils.escape_html(html)
    end
  end
end
