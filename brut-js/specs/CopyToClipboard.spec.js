import { withHTML } from "./SpecHelper.js"

class FakeClipboard {
  constructor() {
    this.resolver = null
    this.writeTextPromise = new Promise( (resolve) => {
      this.resolver = resolve
    })
  }
  writeText(text) {
    this.text = text
    return this.writeTextPromise
  }
}
describe("<brut-copy-to-clipboard>", () => {
  withHTML(`
  <pre><code id="code">dx/exec bin/setup</code></pre>
  <brut-copy-to-clipboard element="code" show-warnings="code">
    <button>Copy</button>
  </brut-copy-to-clipboard>
  `).test("clicking the button copies it to the clipboard", ({window,document,assert}) => {

    const button = document.querySelector("button")
    const code   = document.getElementById("code")

    const clipboard = new FakeClipboard()
    window.navigator.clipboard = clipboard

    button.click()
    clipboard.resolver()
    return clipboard.writeTextPromise.then( () => {
      assert.equal(code.textContent,clipboard.text)
    })
  })
})
