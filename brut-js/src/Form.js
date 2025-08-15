import BaseCustomElement from "./BaseCustomElement"
import RichString from "./RichString"
import AjaxSubmit from "./AjaxSubmit"
import ConstraintViolationMessages from "./ConstraintViolationMessages"

/** A web component that enhances a form it contains to make constraint validations
 * easier to manage and control.
 *
 * This provides two main features:
 *
 * * While the `:user-invalid` selector allows you to target inputs that have been interacted
 *   with (thus avoiding issues when using `:invalid`), this still creates the experience of a
 *   user tabbing off of a control and getting an error message.  If, instead, you only
 *   want to show these errors when a submit has been attempted, this element will
 *   set `submitted-invalid` on itself when that happens, thus allowing you to target invalid
 *   fields only after a submission attempt.
 * * You may wish to control the messaging of client-side constraint violations
 *   beyond what the browser gives you. Assuming you have generated a `<brut-cv-messages input-name="«input name»"></brut-cv-messasges>`, it will be populated with `<brut-cv>` elements for each client-side constraint violation, based on the {@link external:ValidityState} of the control.
 *
 * @fires brut:invalid Fired when any element is found to be invalid
 * @fires brut:valid Fired when no element is found to be invalid.  This should be reliable to know
 * when constraint violations have cleared.
 *
 * @example <caption>Basic Structure Required</caption>
 * <brut-form>
 *   <form ...>
 *     <label>
 *       <input type="text" required name="username">
 *       <brut-cv-messages input-name="username">
 *       </brut-cv-messages>
 *     </label>
 *     <div> <!-- container need not be a label -->
 *       <input type="text" required minlength="4" name="alias">
 *       <brut-cv-messages input-name="alias">
 *       </brut-cv-messages>
 *     </div>
 *     <button>Submit</button>
 *   </form>
 * </brut-form>
 * <!-- after a submit of this form, the HTML will effectively be as follows -->
 * <brut-form submitted-invalid>
 *   <form ...>
 *     <label>
 *       <input type="text" required name="username">
 *       <brut-cv-messages input-name="username">
 *         <brut-cv>This field is required</brut-cv>
 *       </brut-cv-messages>
 *     </label>
 *     <div> <!-- container need not be a label -->
 *       <input type="text" required minlength="4" name="alias">
 *       <brut-cv-messages input-name="alias">
 *         <brut-cv>This field is required</brut-cv>
 *       </brut-cv-messages>
 *     </div>
 *     <button>Submit</button>
 *   </form>
 * </brut-form>
 *
 * @property {boolean} submitted-invalid - set by this element when the form is submitted. Does not trigger any behavior and can be used in CSS.
 * @see ConstraintViolationMessages
 *
 * @customElement brut-form
 */
class Form extends BaseCustomElement {
  static tagName = "brut-form"
  static observedAttributes = [
    "submitted-invalid",
    "show-warnings",
  ]

  #markFormSubmittedInvalid = (event) => {
    this.setAttribute("submitted-invalid","")
  }
  #updateValidity = (event) => {
    this.#updateErrorMessages(event)
  }
  #sendValid = () => {
    this.dispatchEvent(new CustomEvent("brut:valid"))
  }
  #sendInvalid = () => {
    this.dispatchEvent(new CustomEvent("brut:invalid"))
  }

  submittedInvalidChangedCallback() {}

  update() {
    const forms = this.querySelectorAll("form")
    if (forms.length == 0) {
      this.logger.warn("Didn't find any forms. Ignoring")
      return
    }
    forms.forEach( (form) => {
      Array.from(form.elements).forEach( (formElement) => {
        formElement.addEventListener("invalid", this.#updateValidity)
        formElement.addEventListener("invalid", this.#markFormSubmittedInvalid)
        formElement.addEventListener("input", this.#updateValidity)
      })
      form.querySelectorAll(AjaxSubmit.tagName).forEach( (ajaxSubmits) => {
        ajaxSubmits.addEventListener("brut:submitok", this.#sendValid)
        ajaxSubmits.addEventListener("brut:submitinvalid", this.#sendInvalid)
      })
    })
  }

  #updateErrorMessages(event) {
    const element = event.target
    let constraintViolationMessages = []
    if (element.name && element.form) {
      const selector = `${ConstraintViolationMessages.tagName}[input-name='${element.name}']`
      constraintViolationMessages = element.form.querySelectorAll(selector)
      if (constraintViolationMessages.length == 0) {
        this.logger.warn(`Did not find any elements matching ${selector}, so no error messages will be shown`)
      }
    }
    else {
      if (element.name) {
        this.logger.warn("Element has a name (%s), but is not associated with any form.", element.name)
      }
      else {
        this.logger.warn("Element has a form, but has no name, which means we cannot locate %s by input-name", ConstraintViolationMessages.tagName)
      }
    }
    if (constraintViolationMessages.length == 0) {
      return
    }
    let anyErrors = false
    constraintViolationMessages.forEach( (errorLabel) => {
      if (element.validity.valid) {
        errorLabel.clearClientSideMessages()
      }
      else {
        anyErrors = true
        errorLabel.createMessages({
          validityState: element.validity,
          inputName: element.name
        })
      }
    })
    if (anyErrors) {
      this.#sendInvalid()
    }
    else {
      this.#sendValid()
    }
  }
}
export default Form
