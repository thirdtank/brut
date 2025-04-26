require "rexml"

# Produces `<brut-i18n-translation>` entries for the given values. This is used for client-side constraint violation messaging with
# JavaScript.  The `<brut-constraint-violation-message>` tag uses these keys to produce messages on the client.
#
# The default layout included in new Brut apps includes this:
#
# ```html
# <%= component(
#       Brut::FrontEnd::Components::I18nTranslations.new(
#         "general.cv.fe"
#       )
# ) %>
# ```
#
# At runtime, this will produce this:
#
# ```html
# <brut-i18n-translation
#   key="general.cv.fe.badInput"
#   value="%{field} is the wrong type of data">
# </brut-i18n-translation>
# <brut-i18n-translation
#   key="general.cv.fe.patternMismatch"
#   value="%{field} isn't in the right format">
# </brut-i18n-translation>
# <!-- etc -->
# ```
#
# Thus, it will render the translations for all client side errors supported by the browser.  This means that if a
# client side `ValidityState` returns true for, say, `badInput`, JavaScript can look up by the `key` 
# `general.cv.fe.badInput` and find the `value` to produce the string "This field is the wrong type of data".
class Brut::FrontEnd::Components::I18nTranslations < Brut::FrontEnd::Component2

  # Create the component for all keys under the given root
  # @param [String] i18n_key_root A prefix or full key for the i18n messages to render.  For example, if you have `en.cv.fe.valueMissing` and `en.cv.fe.badInput`, an `i18n_key_root` value of `"en.cv.fe"` will result in both of those keys being rendered.
  def initialize(i18n_key_root)
    @i18n_key_root = i18n_key_root
  end

  # @!visibility private
  def view_template
    values = ::I18n.t(@i18n_key_root)
    if values.kind_of?(String)
      values = { "" => values }
    end

    values.each do |key,value|
      if !value.kind_of?(String)
        raise "Key #{key} under #{@i18n_key_root} maps to a #{value.class} instead of a String. For #{self.class} to work, the value must be a String"
      end
      i18n_key = if key == ""
                   @i18n_key_root
                 else
                   "#{@i18n_key_root}.#{key}"
                 end
      attributes = {
        key: i18n_key,
        value: value.to_s,
      }
      if !Brut.container.project_env.production?
        attributes[:show_warnings] = true
        attributes[:id] = "brut-18n-#{key}"
      end

      brut_i18n_translation(**attributes)

    end
  end
end
