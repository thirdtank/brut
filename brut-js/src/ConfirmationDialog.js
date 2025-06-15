import BaseCustomElement from "./BaseCustomElement"
import RichString from "./RichString"

/**
 * Enhances a `DIALOG` element to allow it to be used for confirmation. Mostly useful
 * with {@link Confirm}.
 *
 * This element must:
 *
 * * Wrap a `<DIALOG>` element
 * * Contain an `<H1>` where the message will go
 * * Have a `<BUTTON>` with value `ok` that will be considered the confirmation button.
 * * Have a `<BUTTON>` with value `cancel` that will be considered the denial button.
 *
 * Omitting these will cause this element to not work properly. Set `show-warnings` to see
 * warnings on this.
 *
 * @property {string} message - the message to use to ask for confirmation
 * @property {string} confirm-label - the label to use for the "OK" or "Confirm" button
 *
 * @example <caption>Minimal Example</caption>
 * <brut-confirmation-dialog message="This cannot be undone" confirm-label="DOIT">
 *   <dialog>
 *     <h1></h1>
 *     <button value="ok"></button>
 *     <button value="cancel">Nevermind</button>
 *   </dialog>
 * </brut-confirmation-dialog>
 */
class ConfirmationDialog extends BaseCustomElement {
  static tagName = "brut-confirmation-dialog"
  static observedAttributes = [
    "message",
    "confirm-label",
    "show-warnings"
  ]

  #onClose = () => {}
  #message = new RichString("")
  #confirmLabel = new RichString("OK")

  constructor() {
    super()
    this.okListener = (event) => {
      this.#closeDialog()
      this.#onClose(true)
    }
    this.cancelListener = (event) => {
      this.#closeDialog()
      this.#onClose(false)
    }
  }

  messageChangedCallback({newValue}) {
    this.#message = RichString.fromString(newValue)
  }

  confirmLabelChangedCallback({newValue}) {
    this.#confirmLabel = RichString.fromString(newValue)
  }

  /**
   * Call this to show the dialog.  When the dialog is closed, `onClose` is called with the result.
   *
   * @param {function} onClose - a function called with either `true` or `false`, if the dialog was confirmed or 
   * denied, respectively.
   *
   * @example
   * dialog.showModal( (confirmed) => {
   *   if (confirmed) {
   *     form.submit()
   *   }
   *   else {
   *     // do nothing
   *   }
   * })
   */
  showModal(onClose) {
    const dialog = this.#dialog
    if (dialog) {
      this.#onClose = onClose || (() => {})
      dialog.showModal()
    }
    else {
      this.logger.warn("No <dialog> found to show")
    }
  }

  get #dialog() {
    return this.querySelector("dialog")
  }

  #closeDialog() {
    const dialog = this.#dialog
    if (dialog) {
      dialog.close()
    }
  }

  update() {
    const dialog = this.#dialog
    if (!dialog) {
      this.logger.warn("Could not find a <dialog> - this custom element won't do anything")
      return
    }
    this.#setMessage(dialog)
    this.#setupButtons()
  }

  #setMessage(dialog) {
    const h1 = dialog.querySelector("h1")
    if (h1) {
      if (this.#message.isBlank()) {
        h1.textContent = null
      }
      else {
        h1.textContent = this.#message.toString()
      }
    }
    else {
      this.logger.warn("Dialog had no <h1>, so nowhere to put the message")
    }
  }

  #setupButtons() {
    const okButton     = this.querySelector("button[value='ok']")
    const cancelButton = this.querySelector("button[value='cancel']")

    if (!okButton || !cancelButton) {
      if (!okButton)     { this.logger.warn("no <button value='ok'> which is required for this dialog to work") }
      if (!cancelButton) { this.logger.warn("no <button value='cancel'> which is required for this dialog to work") }
      return
    }

    okButton.textContent = this.#confirmLabel

    okButton.addEventListener("click"     , this.okListener)
    cancelButton.addEventListener("click" , this.cancelListener)
  }
}
export default ConfirmationDialog
