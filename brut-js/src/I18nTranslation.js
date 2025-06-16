import BaseCustomElement from "./BaseCustomElement"

/** Manages a translation based on a key and value, with the value potentially having interpolation.
 *
 * This is intended to be server-rendered with the subset of keys the server manages that are relevant
 * to the front-end.  Any other code on the page can then locate an element with the desired key and
 * call `translation` to get the human-readable key.  It is assumed that the server would render
 * in the language required by the visitor, so there is no need to first select by locale.
 *
 * @property {string} key - an i18n key, presumably dot-delimited, however it can be any valid attribute value.
 * @property {string} value - the value of the key, in the browser's locale. It may contain placeholders for interpolation using `%{«placeholder»}` syntax.
 *
 * @example
 * <brut-i18n-translation key="greeting" value="Hello %{username}"></brut-i18n-translation>
 *
 * @customElement brut-i18n-translation
 */
class I18nTranslation extends BaseCustomElement {
  static tagName = "brut-i18n-translation"

  static observedAttributes = [
    "show-warnings",
    "key",
    "value",
  ]

  #key = null
  #value = ""

  keyChangedCallback({newValue}) {
    this.#key = newValue
  }

  valueChangedCallback({newValue}) {
    this.#value = newValue ? String(newValue) : ""
  }

  /**
   * Called by other JavaScript to get the translated string.
   * @param {Object} interpolatedValues - Object where the keys are placeholders in the string for interpolation and the values are
   * the values to replace.  Placeholders not in the translated value are ignored. Missing placeholders won't cause an error, but the
   * placeholder will be present verbatim in the translated string.
   *
   * @example
   * const element = document.querySeletor("brut-i18n-translation[key='greeting']")
   * if (element) {
   *   const translation = element.translation({ username: "Pat" })
   *   alert(translation) // Shows 'Hello Pat'
   * }
   */
  translation(interpolatedValues) {
    return this.#value.replaceAll(/%\{([^}%]+)\}/g, (match,key) => {
      if (interpolatedValues[key]) {
        return interpolatedValues[key]
      }
      return match
    })
  }

}
export default I18nTranslation
