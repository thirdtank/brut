# Use this to access translations in any CLI.
# This implementation does support blocks yielded to {#t}, however
# their values are not necessarily HTML-escaped.
module Brut::I18n::ForCLI
  include Brut::I18n::BaseMethods
  def safe(string) = string
  def capture(&block) = block.()
  def html_escape(value) = value
end
