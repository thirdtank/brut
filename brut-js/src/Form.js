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
 *   beyond what the browser gives you. Assuming your `INPUT` tags are inside a container
 *   like `LABEL`, a `brut-cv` tag found in that container
 *   (i.e. a sibling of your `INPUT`) will be modified to contain error messages specific
 *   to the {@link external:ValidityState} of the control.
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
 *       <brut-cv-messages>
 *       </brut-cv-messages>
 *     </label>
 *     <div> <!-- container need not be a label -->
 *       <input type="text" required minlength="4" name="alias">
 *       <brut-cv-messages>
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
 *       <brut-cv-messages>
 *         <brut-cv>This field is required</brut-cv>
 *       </brut-cv-messages>
 *     </label>
 *     <div> <!-- container need not be a label -->
 *       <input type="text" required minlength="4" name="alias">
 *       <brut-cv-messages>
 *         <brut-cv>This field is required</brut-cv>
 *       </brut-cv-messages>
 *     </div>
 *     <button>Submit</button>
 *   </form>
 * </brut-form>
 *
 * @property {boolean} submitted-invalid - set by this element when the form is submitted. Does not trigger any behavior and can be used in CSS.
 * @see ConstraintViolationMessages
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
    const selector = ConstraintViolationMessages.tagName
    let errorLabels = element.parentNode.querySelectorAll(selector)
    if (errorLabels.length == 0) {
      if (element.name && element.form) {
        const moreGeneralSelector = `${ConstraintViolationMessages.tagName}[input-name='${element.name}']`
        errorLabels = element.form.querySelectorAll(moreGeneralSelector)
        if (errorLabels.length == 0) {
          this.logger.warn(`Did not find any elements matching ${selector} or ${moreGeneralSelector}, so no error messages will be shown`)
        }
      }
      else {
        this.logger.warn("Did not find any elements matching %s and the form element has %s %s",
          selector,
          element.name ? "no name" : "a name, but",
          element.form ? "no form" : "though has a form")
      }
    }
    if (errorLabels.length == 0) {
      return
    }
    let anyErrors = false
    errorLabels.forEach( (errorLabel) => {
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
