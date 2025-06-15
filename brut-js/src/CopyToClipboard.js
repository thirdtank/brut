import BaseCustomElement from "./BaseCustomElement"

/** Wraps a `<BUTTON>` that will copy text from another element into the system clipboard.  It will set various attributes on itself
 * to allow styling the states of the process.
 *
 * Overall, the flow is as follows:
 *
 * 1. When the button is clicked, its default is prevented, and the element with the id of the `element` attribute is located.
 * 2. If found, this element gets the `copying` attribute set.
 * 3. If the copy completes successfully:
 *    a. `copying` is removed
 *    b. `copied` is set
 *    c. `copied` is scheduled for removal in 2000ms or the number of milliseconds in the `copied-lifetime` attribute.
 * 4. If the copy failed:
 *    a. `copying` is removed
 *    b. `errored` is set
 *    c. The `brut:copyfailed` event is fired. It's detail contains a `text:` value with the text that was attempted to be copied.
 *
 * The intention is to use these attributes to style whatever UX you want.
 *
 * @property {string} element - ID of the element whose `textContent` is what will be copied to the clipboard.
 * @property {number} copied-lifetime - number of milliseconds to wait before clearing the `copied` attribute after a successful copy.
 * @property {boolean} copying - Set after a copy is initiated, but before it completes
 * @property {boolean} copied - Set after a copy is completed successfully
 * @property {boolean} errored - Set after a copy is fails
 *
 * @fires brut:copyfailed Fired when the copy fails to complete
 *
 * @example
 * <pre><code id="code">dx/exec bin/setup</code></pre>
 * <brut-copy-to-clipboard element="code">
 *   <button>Copy</button>
 * </brut-copy-to-clipboard>
 */
class CopyToClipboard extends BaseCustomElement {
  static tagName = "brut-copy-to-clipboard"

  static observedAttributes = [
    "element",
    "copied-lifetime",
  ]

  #elementId = null
  #copiedLifetime = 2000

  #copyCode = (event) => {
    event.preventDefault()

    const element = document.getElementById(this.#elementId)

    if (!element) {
      this.logger.info("No element with id %s, so nothing to copy",this.#elementId)
      return
    }
    this.setAttribute("copying",true)

    const text = element.textContent

    navigator.clipboard.writeText(text).then( () => {
      this.setAttribute("copied", true)
    }).catch( (e) => {
      this.setAttribute("errored", true)
      this.dispatchEvent(new CustomEvent("brut:copyfailed", { detail: { text: text }}))
    }).finally( () => {
      this.removeAttribute("copying")
      setTimeout( () => this.removeAttribute("copied"), 2000)
    })
  }

  update() {
    const button = this.querySelector("button")
    if (button) {
      button.addEventListener("click", this.#copyCode)
    }
    else {
      this.logger.info("There is no button, so no way to initiate a copy")
    }
  }

  elementChangedCallback({newValue}) {
    this.#elementId = newValue
  }

  copiedLifetimeChangedCallback({newValue}) {
    const newValueAsInt = parseInt(newValue)
    if (!isNaN(newValueAsInt)) {
      this.#copiedLifetime = newValueAsInt
    }
    else {
      this.logger.info("Value '%s' for copied-lifetime is not a number. Ignoring it",newValue)
    }
  }
}
export default CopyToClipboard
