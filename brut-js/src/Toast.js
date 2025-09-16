import { BaseCustomElement, RichString, Message } from "brut-js"

/**
 * Support for a toast component, which is a momentary message shown to the user, for example
 * if an aynchronous update has occured.
 *
 * To use this element, you should set up your CSS so that the element is hidden if there is no `key`
 * attribute set.  When the `key` attribute *is* set, the element should be shown.  You can use CSS animations
 * for this as needed, but the main thing to remember is that, without a `key` attribute, this element
 * should not be visible.
 *
 * The `key` attribute is expected to be an i18n key that references a `<brut-i18n-message>` on
 * the page, which contains the actual message to show the visitor.  When the `key` attribute is
 * set, this component will find an `<output>` inside itself, and replace the entire contents
 * with a `<brut-message>` component, using the same `key`.  This will cause the `<brut-message>`
 * to look up the key and put that text into the element.
 *
 * In addition to this lookup, this element will set appropriate ARIA attributes on the
 * created `<brut-message>` element.
 *
 * Further, if there is a `<button>` inside this element, it will be used to close the toast by removing the
 * `key` attribute (which, assuming your CSS is correct, will hide the element).
 *
 * @property {string} key - an I18n key of the message to show in the toast.  When you generate
 *                          the toast's HTML on the server, do not set key.  Then, when you need
 *                          to display the toast, use JavaScript to set the key. This will
 *                          trigger its behavior as described above.
 *
 * @example
 * <style>
 *   brut-toast {
 *     display: none;
 *   }
 *   brut-toast[key] {
 *     display: block;
 *   }
 * </style>
 * <brut-i18n-translation key="toast.saved">Save successful</brut-i18n-translation>
 * <brut-toast>
 *   <div>
 *   <output></output>
 *   <button>Close</button>
 *   </div>
 * </brut-toast>
 * <!-- now, if you set the key to "toast.saved", the HTML will be changed as follows: -->
 * <brut-toast key="toast.saved">
 *   <div>
 *   <output>
 *     <brut-message key="toast.saved" role="status" aria-live="polite" aria-atomic="true">
 *       Save successful
 *     </brut-message>
 *   </output>
 *   <button>Close</button>
 *   </div>
 * </brut-toast>
 */
class Toast extends BaseCustomElement {
  static tagName = "brut-toast"

  static observedAttributes = [
    "show-warnings",
    "key",
  ]

  #key = null
  #closeListener = (event) => {
    event.preventDefault()
    this.removeAttribute("key")
  }

  keyChangedCallback({newValue}) {
    this.#key = RichString.fromString(newValue)
  }

  update() {
    const closeButton = this.querySelector("button")

    if (closeButton) {
      closeButton.addEventListener("click", this.#closeListener)
    }

    if (!this.#key) {
      return
    }
    const output = this.querySelector("output")
    if (!output) {
      this.logger.warn("No <output> element found, so toast will not be displayed")
      return
    }
    const messageNode = Message.createElement(document,{
      "key": this.#key,
      "role": "status",
      "aria-live": "polite",
      "aria-atomic": "true"
    })
    output.replaceChildren(messageNode)
    this.style.animation = "none"
    this.offsetWidth // Trigger reflow to restart the animation
    this.style.animation = ""
  }
}
export default Toast
