import BaseCustomElement from "./BaseCustomElement"

/** When the value of the wrapped form element(s) fire(s) a change event, the form is submitted.
 * This will only work if it is inside a form *and* the form elements it contains are part of the form.
 * That means if your input/textarea/select uses the `form` attribute, this custom element has no effect.
 *
 * @example
 *
 * <form>
 *   <brut-autosubmit>
 *     <!-- when a selection is made, the form is submitted -->
 *     <select name="status">
 *       <option value="draft">Draft</option>
 *       <option value="ready">Ready</option>
 *       <option value="published">Published</option>
 *     </select>
 *   </brut-autosubmit>
 *   <!-- when the value is changed, form is NOT submitted -->
 *   <input type="text" value="notes">
 *   <button>Save</button>
 * </form>
 *
 * @customElement brut-autosubmit
 */
class Autosubmit extends BaseCustomElement {
  static tagName = "brut-autosubmit"

  static observedAttributes = [
    "show-warnings",
  ]

  #submitForm = (event) => {
    const form = this.closest("form")
    if (!form) {
      this.logger.info("No longer a form containing this element")
      return
    }
    if (event.target.form != form) {
      this.logger.info("Event target %o's form is not the form that contains this element",event.target)
      return
    }
    form.requestSubmit()
  }

  update() {
    const form = this.closest("form")
    if (!form) {
      this.logger.info("No form containing this element - nothing to autosubmit")
      return
    }
    const inputs = Array.from(this.querySelectorAll("input, textarea, select")).filter( (element) => {
      return element.form == form
    })
    if (inputs.length == 0) {
      this.logger.info("No input, textarea, or select inside this element belongs to the form containing this element")
      return
    }
    inputs.forEach( (input) => {
      input.addEventListener("change", this.#submitForm)
    })
  }
}
export default Autosubmit
