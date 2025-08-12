import BaseCustomElement from "./BaseCustomElement"
import RichString from "./RichString"
import ConfirmationDialog from "./ConfirmationDialog"

/** Confirms form submissions with the user before allowing the form to be submitted. This is applied
 * to buttons, not forms, to allow for finer control over the behavior.
 *
 * * This only works for `button` or `input type=submit`
 * * The elements must have a form, either by being inside a form or having
 *   a `form` attribute.
 * * If the form is not valid, it will not show the confirmation dialog.
 *
 *
 * By default, this will use {@link external:Window#confirm}.  if "OK" is pressed,
 * the button click goes through and the form would be submitted. If "Cancel" is pressed,
 * the event is prevented.
 *
 * If there is a `brut-confirmation-dialog` on the page, this component can use that, possibly
 * with help from the `dialog` attribute as followed:
 *
 * * If `dialog` is set:
 *   - If that id is on a `<brut-confirmation-dialog>` that is used.
 *   - If not, `window.confirm` is used.
 * * If `dialog` is not set:
 *   - If there is exactly one `<brut-confirmation-dialog>` on the page, this is used.
 *   - If there is more than one, or no `<brut-confirmation-dialog>`s, `window.confirm` is used.
 *
 * If the wrong dialog or notification method is happening, set `show-warnings` on the element, and it will
 * print out why it's doing what it's doing.
 *
 * @see ConfirmationDialog
 *
 * @property {string} message - the message to show that asks for confirmation. It should be written such that
 *                              "OK" is grammatically correct for confirmation and "Cancel" is for aborting.
 * @property {string} dialog - optional ID of the `brut-confirmation-dialog` to use instead of `window.confirm`.
 *                             If there is no such dialog or the id references the wrong element type,
 *                             `window.confirm` will be used.  Setting `show-warnings` will generate a warning for this.
 *
 * @customElement brut-confirm-submit
 */
class ConfirmSubmit extends BaseCustomElement {
  static tagName = "brut-confirm-submit"

  static observedAttributes = [
    "message",
    "dialog",
    "show-warnings",
  ]

  #message      = new RichString("")
  #confirming   = false
  #dialogId     = null

  messageChangedCallback({newValue}) {
    this.#message = new RichString(newValue || "")
  }

  dialogChangedCallback({newValue}) {
    this.#dialogId = RichString.fromString(newValue)
  }

  constructor() {
    super()
    this.onClick = (event) => {
      if (this.#confirming) {
        this.#confirming = false
        return
      }
      if (this.#message.isBlank()) {
        this.logger.warn("No message provided, so cannot confirm")
        return
      }
      const form = event.currentTarget.form

      if (!form) {
        this.logger.warn("Element was not part of a form, so cannot confirm submission")
        return
      }

      if (!form.checkValidity()) {
        return
      }

      const dialog = this.#findDialog()
      if (dialog) {
        event.preventDefault()
        dialog.setAttribute("message",this.#message.toString())
        const buttonLabel = event.target.getAttribute("aria-label") || event.target.textContent
        dialog.setAttribute("confirm-label",buttonLabel)
        this.#confirming = true
        dialog.showModal((confirm) => {
          if (confirm) {
            event.target.click()
          }
          else {
            this.#confirming = false
          }
        })
      }
      else {
        const result = window.confirm(this.#message)
        if (!result) {
          event.preventDefault()
        }
      }
    }
  }

  #findDialog() {
    if (this.#dialogId) {
      const dialog = document.getElementById(this.#dialogId)
      if (dialog) {
        if (dialog.tagName.toLowerCase() != ConfirmationDialog.tagName) {
          throw `${this.#dialogId} is the id of a '${dialog.tagName}', not '${ConfirmationDialog.tagName}'`
        }
        return dialog
      }
      this.logger.warn(`No dialog with id ${this.#dialogId} - using window.confirm as a fallback`)
      return null
    }
    const dialogs = document.querySelectorAll(ConfirmationDialog.tagName)
    if (dialogs.length == 1) {
      return dialogs[0]
    }
    if (dialogs.length == 0) {
      this.logger.warn(`No '${ConfirmationDialog.tagName}' found in document - using window.confirm as a fallback`)
      return null
    }
    throw `Found ${dialogs.length} '${ConfirmationDialog.tagName}' elements. Not sure which to use. Remove all but one or specify the 'dialog' attribute on this element to specify which one to use`
  }

  update() {
    this.querySelectorAll("button").forEach( (button) => button.addEventListener("click", this.onClick) )
    this.querySelectorAll("input[type=submit]").forEach( (button) => button.addEventListener("click", this.onClick) )
  }
}
export default ConfirmSubmit
