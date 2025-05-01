module Brut::I18n::ForBackEnd
  include Brut::I18n::BaseMethods
  def safe(string) = string
  def capture(&block) = block.()
end
