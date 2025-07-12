import BaseCustomElement from "./BaseCustomElement"
import RichString from "./RichString"
import ConstraintViolationMessage from "./ConstraintViolationMessage"

/**
 * Custom element to translate keys from {@link external:ValidityState} into 
 * actual messges for a human.  This works by inserting `<brut-cv>` elements
 * as children, where the key represents the particular errors present in the `ValidityState` passed
 * to `createMessages`. Note that this will not insert an element for `customError`, since there can't be
 * any sort of general error message to correspond to that.
 *
 * @property {string} input-name if set, this indicates this element contains constraint violation messages
 *                               for the input with this name inside the form this element is in. Currently doesn't affect
 *                               this element's behavior, however AjaxSubmit will use it to locate where it 
 *                               should insert server-side errors.
 *
 * @see Form
 * @see ConstraintViolationMessage
 * @see AjaxSubmit
 *
 * @customElement brut-cv-messages
 */
class ConstraintViolationMessages extends BaseCustomElement {
  static tagName = "brut-cv-messages"

  static observedAttributes = [
    "show-warnings",
    "input-name",
  ]

  inputNameChangedCallback({newValue}) {
    // attribute listed for documentation purposes only
  }

  /** 
   * Creates error messages based on the passed `ValidityState` and input name.
   *
   * This should be called as part of a Form validation event to provide a customized UX for
   * the error messages, beyond what the browser would do by default.  The keys used are the same
   * as the attributes of a `ValidityState`, so for example, a range underflow would mean that `validity.rangeUnderflow` would return
   * true.  Thus, a `<brut-cv>` would be created with `key="cv.cs.rangeUnderflow"`.
   *
   * The `cv.cs` is hard-coded to be consistent with Brut's server-side translation management.
   *
   * @param {ValidityState} validityState - the return from an element's `validity` when it's found to have constraint violations.
   * @param {String} inputName - the element's `name`.
   */
  createMessages({validityState,inputName}) {
    const errors = this.#VALIDITY_STATE_ATTRIBUTES.filter( (attribute) => validityState[attribute] )
    this.clearClientSideMessages()
    errors.forEach( (key) => {
      const options = {
        key: key,
        "input-name": inputName,
      }
      const showWarnings = this.getAttribute("show-warnings")
      if (showWarnings != null) {
        options["show-warnings"] = showWarnings
      }
      const element = ConstraintViolationMessage.createElement(document,options)
      this.appendChild(element)
    })
  }

  /**
   * Clear any client-side messages previously inserted by another element.
   * This is useful to remove potentially out-of-date messages to replace with up-to-date ones.
   */
  clearClientSideMessages() {
    this.querySelectorAll(ConstraintViolationMessage.clientSideSelector()).forEach( (element) => {
      this.removeChild(element)
    })
  }

  /**
   * Clear any server-side messages previously inserted by another element or rendered from the server.
   * This is useful to remove potentially out-of-date messages to replace with up-to-date ones.
   */
  clearServerSideMessages() {
    this.querySelectorAll(ConstraintViolationMessage.serverSideSelector()).forEach( (element) => {
      this.removeChild(element)
    })
  }

  #VALIDITY_STATE_ATTRIBUTES = [
    "badInput",
    "patternMismatch",
    "rangeOverflow",
    "rangeUnderflow",
    "stepMismatch",
    "tooLong",
    "tooShort",
    "typeMismatch",
    "valueMissing",
    // customError omitted, since it makes no sense as a general error key to look up
  ]
}
export default ConstraintViolationMessages
