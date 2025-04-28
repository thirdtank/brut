# I18n for components or pages, which are assumed to be Phlex components.
# To use this outside of a Phlex context, you should use 
# {Bruiti::I18n::ForCLI}, however to use this module anyway, you must:
#
# * Define `safe` to accept a string and return a string.
# * Define `capture` to accept a block and return its contents as a string.
module Brut::I18n::ForHTML
  include Brut::I18n::BaseMethods
  def t(...)
    safe(super)
  end
end
