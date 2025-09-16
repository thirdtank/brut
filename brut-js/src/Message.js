import BaseCustomElement from "./BaseCustomElement"
import RichString from "./RichString"
import I18nTranslation from "./I18nTranslation"

/** Renders a translated message for a given key, handling all the needed interpolation based
 * on the existence of `<brut-i18n-translation>` elements on the page.
 *
 * When the `key` attribute has a value, this element will locate the `<brut-i18-translation>` element and call `translate`. Note that
 * interpolation is not supported.
 *
 * @property {string} key - the i18n translation key to use.  It must map to the `key` of a `<brut-i18n-translation>` on the page or
 * the element will not render any text.
 *
 * @see I18nTranslation
 * @see ConstraintViolationMessage
 *
 * @customElement brut-message
 */
class Message extends BaseCustomElement {
  static tagName = "brut-message"
  static observedAttributes = [
    "show-warnings",
    "key",
  ]

  /*
   * Creates a new `<brut-message>` element with the given attributes.
   */
  static createElement(document,attributes) {
    const element = document.createElement(Message.tagName)
    Object.entries(attributes).forEach(([name,value]) => {
      if (value !== null && value !== undefined) {
        element.setAttribute(name,value)
      }
    })
    return element
  }

  #key = null

  keyChangedCallback({newValue}) {
    this.#key = newValue
  }

  update() {
    if (!this.#key) {
      this.logger.info("No key attribute, so can't do anything")
      return
    }

    const selector = `${I18nTranslation.tagName}[key='${this.#key}']`
    const translation = document.querySelector(selector)
    if (!translation) {
      this.logger.info("Could not find translation based on selector '%s'",selector)
      return
    }

    this.textContent = RichString.fromString(translation.translation(), {allowBlank: true }).capitalize().toString()
  }
}

export default Message
