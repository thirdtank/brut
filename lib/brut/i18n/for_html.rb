# I18n for components or pages, which are assumed to be Phlex components.
# This will do HTML escaping as follows:
#
# * Interpolated values are always HTML-escaped
# * When a block is used, that value is assumed to be safe HTML,
#   and generated outside the current Phlex context. It's value is
#   captured (via `#capture`) and then declared HTML safe by being
#   passed to `#safe`.
#
# Unless you put HTML injections into your translations file, this should result
# in safe HTML in any translation.
#
# This module provides two features that aren't part of {#Brut::I18n::BaseMethods}:
#
# * {#t} calls `#safe` on its return value, indicating that the string is safe. To use
#   this string in a Phlex view, you *must* call `#raw` and pass it the string.
# * {#html_escape} is implemented to escape values it's given.
#
#
# @example
#   class StatusComponent < AppComponent
#     def initialize(status:)
#       @status = status
#     end
#     def view_template
#       div do
#         raw(
#           t( [ :status, @status ] )
#         )
#       end
#     end
#   end
#
module Brut::I18n::ForHTML
  include Brut::I18n::BaseMethods
  def t(...)
    safe(super)
  end
  def html_escape(value) = CGI.escapeHTML(value)
end
