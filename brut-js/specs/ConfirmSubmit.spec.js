import { withHTML } from "./SpecHelper.js"

describe("<brut-confirm-submit>", () => {
  describe("without an explicit dialog", () => {
    withHTML(`
    <form>
      <input type="text" name="text">
      <brut-confirm-submit message='You sure?'>
        <button>Save</button>
        <input type="submit" value="Submit">
      </brut-confirm-submit>
    </form>
    `).test("uses window.confirm and cancels the click on Cancel", ({window,document,assert}) => {
      const form   = document.querySelector("form")
      const button = document.querySelector("button")

      let submitted = false
      form.addEventListener("submit", (event) => {
        event.preventDefault()
        submitted = true
      })

      let shown        = false
      let messageShown = null

      window.confirm = (message) => {
        shown = true
        messageShown = message
        return false // "Cancel"
      }

      button.click()
      assert(shown)
      assert.equal(messageShown,"You sure?")
      assert(!submitted)
    }).test("uses window.confirm and allows the click on OK", ({window,document,assert}) => {
      const form   = document.querySelector("form")
      const button = document.querySelector("button")

      let submitted = false
      form.addEventListener("submit", (event) => {
        event.preventDefault()
        submitted = true
      })

      let shown        = false
      let messageShown = null

      window.confirm = (message) => {
        shown = true
        messageShown = message
        return true // "OK"
      }


      button.click()
      assert(shown)
      assert.equal(messageShown,"You sure?")
      assert(submitted)
    }).test("uses window.confirm on submit button", ({window,document,assert}) => {
      const form   = document.querySelector("form")
      const button = document.querySelector("input[type=submit]")

      let submitted = false
      form.addEventListener("submit", (event) => {
        event.preventDefault()
        submitted = true
      })

      let shown        = false
      let messageShown = null

      window.confirm = (message) => {
        shown = true
        messageShown = message
        return true // "OK"
      }


      button.click()
      assert(shown)
      assert.equal(messageShown,"You sure?")
      assert(submitted)
    })
  })
  describe("with an implicit dialog", () => {
    withHTML(`
    <form>
      <input type="text" name="text">
      <brut-confirm-submit message='You sure?' show-warnings>
        <button>Save</button>
        <input type="submit" value="Submit">
      </brut-confirm-submit>
    </form>
    <brut-confirmation-dialog>
      <dialog>
        <h1></h1>
        <button value="ok">OK</button>
        <button value="cancel">Cancel</button>
      </dialog>
    </brut-confirmation-dialog>
    `).test("uses the dialog and cancels the click on Cancel", ({window,document,assert}) => {
      const form   = document.querySelector("form")
      const button = document.querySelector("button")
      const dialog = document.querySelector("dialog")

      let submitted = false
      form.addEventListener("submit", (event) => {
        event.preventDefault()
        submitted = true
      })

      button.click()

      assert(dialog.open)
      const message = dialog.querySelector("h1").textContent
      assert.equal(message,"You sure?")

      const cancel = dialog.querySelector("button[value=cancel]")
      cancel.click()

      assert(!submitted)
    }).test("uses the dialog and submits the click on OK", ({window,document,assert}) => {
      const form   = document.querySelector("form")
      const button = document.querySelector("button")
      const dialog = document.querySelector("dialog")

      let submitted = false
      form.addEventListener("submit", (event) => {
        event.preventDefault()
        submitted = true
      })

      button.click()

      assert(dialog.open)
      const message = dialog.querySelector("h1").textContent
      assert.equal("You sure?",message)

      const ok = dialog.querySelector("button[value=ok]")
      assert.equal(ok.textContent,button.textContent)
      ok.click()
      assert(submitted)
    })
  })
  describe("with multiple dialogs", () => {
    withHTML(`
    <form>
      <input type="text" name="text">
      <brut-confirm-submit message='You sure?' dialog="dialog-2" show-warnings>
        <button>Save</button>
        <input type="submit" value="Submit">
      </brut-confirm-submit>
    </form>
    <brut-confirmation-dialog id="dialog-1">
      <dialog>
        <h1></h1>
        <button value="ok">OK</button>
        <button value="cancel">Cancel</button>
      </dialog>
    </brut-confirmation-dialog>
    <brut-confirmation-dialog id="dialog-2">
      <dialog>
        <h1></h1>
        <button value="ok">OK</button>
        <button value="cancel">Cancel</button>
      </dialog>
    </brut-confirmation-dialog>
    `).test("click event uses the identified dialog", ({window,document,assert}) => {
      const form   = document.querySelector("form")
      const button = form.querySelector("button")
      const dialog = document.getElementById("dialog-2").querySelector("dialog")

      let submitted = false
      form.addEventListener("submit", (event) => {
        event.preventDefault()
        submitted = true
      })

      button.click()

      assert(dialog.open)

      const message = dialog.querySelector("h1").textContent
      assert.equal("You sure?",message)

      const ok = dialog.querySelector("button[value=ok]")
      assert.equal(ok.textContent,button.textContent)
      ok.click()
      assert(submitted)
    })
  })
})
