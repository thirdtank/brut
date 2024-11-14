module Brut::I18n::ForHTML
  include Brut::I18n::BaseMethods
  def html_safe(string) = Brut::FrontEnd::Templates::HTMLSafeString.from_string(string)
end
