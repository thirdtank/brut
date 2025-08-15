import BaseCustomElement from "./BaseCustomElement"
import RichString from "./RichString"
import I18nTranslation from "./I18nTranslation"

/** Like {@link Message} but specific to constraint violations of input fields.  This accepts the name
 * of an input field via `input-name`, which can be used to locate the field's localized name.
 *
 * Here is how the field's name is determined:
 *
 * 1. It will look for a `<brut-i18n-translation>` element with the `key` `cv.cs.fieldNames.«input-name»`.
 * 2. If that's not found, it will attempt to use "this field" by locating a `<brut-i18n-translation>` element with the `key`
 *    `cv.this_field` (the underscore being what is used on Brut's server side).
 * 3. If that is not found, it will use the literaly string "this field" and emit a console warning.
 *
 * @property {string} key - the i18n translation key to use.  It must map to the `key` of a `<brut-i18n-translation>` on the page or
 * the element will not render any text.
 * @property {string} input-name - the name of the input, used to insert into the message, e.g. "Title is required".
 * @property {boolean} server-generated if true, this indicates the element's HTML was generated on the server.
 *           This means that your CSS can target it for display in all cases.  If this is not present,
 *           you may want to avoid showing this element if the form has not been submitted yet.
 *           Does not affect behavior.
 * @property {boolean} server-side if true, this indicates the element contains constraint violation messages
 *           from the server.  Does not affect behavior.
 * @property {boolean} client-side if true, this indicates the element contains constraint violation messages
 *           from the client, however they may have been generated from the server, since the server may
 *           re-evaluate the client-side constraints.  Does not affect behavior of this tag.
 *
 * @see I18nTranslation
 * @see ConstraintViolationMessages
 * @see Message
 *
 * @customElement brut-cv
 */
class ConstraintViolationMessage extends BaseCustomElement {
  static tagName = "brut-cv"

  static observedAttributes = [
    "show-warnings",
    "key",
    "input-name",
    "server-side",
    "client-side",
    "server-generated",
  ]

  static createElement(document,attributes) {
    const element = document.createElement(ConstraintViolationMessage.tagName)
    element.setAttribute("key",this.i18nKey("cs", attributes.key))
    element.setAttribute("input-name",attributes["input-name"])
    element.setAttribute("client-side","")
    if (Object.hasOwn(attributes,"show-warnings")) {
      element.setAttribute("show-warnings",attributes["show-warnings"])
    }
    return element
  }

  static markServerSide(element) {
    if (element.tagName.toLowerCase() == this.tagName) {
      element.setAttribute("server-side", true)
    }
  }

  static clientSideSelector() {
    return `${this.tagName}:not([server-side])`
  }

  static serverSideSelector() {
    return `${this.tagName}[server-side]`
  }

  /** Returns the I18N key used for front-end constraint violations. This is useful
   * if you need to construct a key and want to follow Brut's conventions on how they
   * are managed.
   *
   * @param {...String} keyPath - parts of the path of the key after the namespace that Brut manages.
   */
  static i18nKey(...keyPath) {
    const path = [ "cv" ]
    return path.concat(keyPath).join(".")
  }

  #key          = null
  #inputNameKey = null
  #thisFieldKey = this.#i18nKey("this_field")

  keyChangedCallback({newValue}) {
    this.#key = newValue
  }

  inputNameChangedCallback({newValue}) {
    this.#inputNameKey = this.#i18nKey("cs", "fieldNames", newValue)
  }

  serverSideChangedCallback({newValueAsBoolean}) {
    // attribute listed for documentation purposes only
  }
  clientSideChangedCallback({newValueAsBoolean}) {
    // attribute listed for documentation purposes only
  }
  serverGeneratedChangedCallback({newValueAsBoolean}) {
    // attribute listed for documentation purposes only
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

    const fieldNameSelector = `${I18nTranslation.tagName}[key='${this.#inputNameKey}']`
    const thisFieldSelector = `${I18nTranslation.tagName}[key='${this.#thisFieldKey}']`

    let fieldNameTranslation = document.querySelector(fieldNameSelector)
    if (!fieldNameTranslation) {
      this.logger.info("Could not find translation for input/field name based on selector '%s'. Will try 'this field' fallback",fieldNameSelector)
      fieldNameTranslation = document.querySelector(thisFieldSelector)
      if (!fieldNameTranslation) {
        this.logger.info("Could not find translation for 'this field' fallback key, based on selector '%s'",thisFieldSelector)
      }
    }

    const fieldName = fieldNameTranslation ? fieldNameTranslation.translation() : "this field"
    this.textContent = RichString.fromString(translation.translation({ field: fieldName })).capitalize().toString()
  }

  /** Helper that calls the static version */
  #i18nKey(...keyPath) {
    return this.constructor.i18nKey(...keyPath)
  }


}
export default ConstraintViolationMessage
