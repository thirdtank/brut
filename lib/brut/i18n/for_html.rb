# I18n for components or pages, which are assumed to be Phlex components.
# To use this outside of a Phlex context, either use {Brut::I18n::BaseMethods} directly,
# use {Brut::I18n::ForCLI}, or implement `safe` to return a string.
module Brut::I18n::ForHTML
  include Brut::I18n::BaseMethods
  def t(...)
    safe(super)
  end
end
