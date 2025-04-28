module Brut::I18n::ForCLI
  include Brut::I18n::BaseMethods
  def safe(string) = string
  def capture(&block) = block.()
end
