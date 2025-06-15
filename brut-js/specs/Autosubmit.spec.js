import { withHTML } from "./SpecHelper.js"

describe("<brut-autosubmit>", () => {
  withHTML(`
    <form id="form-1">
      <brut-autosubmit>
        <select name="status">
          <option value="draft">Draft</option>
          <option value="ready">Ready</option>
          <option value="published">Published</option>
         </select>
         <textarea></textarea>
         <input type="text" id="input-1">
         <input type="text" id="input-2" form="form-2">
      </brut-autosubmit>
      <button>Save</button>
    </form>
    <form id="form-2">
      <button>Save</button>
    </form>
  `).test("<select> 'change' event submits the form", ({window,document,assert}) => {

    const form   = document.getElementById("form-1")
    const select = form.querySelector("select")

    let submitted = false

    form.addEventListener("submit", (event) => {
      event.preventDefault()
      submitted = true
    })
    const event = new window.Event("change",{})
    select.dispatchEvent(event)
    assert(submitted)
  }).test("<textarea> 'change' event submits the form", ({window,document,assert}) => {

    const form     = document.getElementById("form-1")
    const textarea = form.querySelector("textarea")

    let submitted = false

    form.addEventListener("submit", (event) => {
      event.preventDefault()
      submitted = true
    })
    const event = new window.Event("change",{})
    textarea.dispatchEvent(event)
    assert(submitted)
  }).test("<input> 'change' event submits the form", ({window,document,assert}) => {

    const form  = document.getElementById("form-1")
    const input = document.getElementById("input-1")

    let submitted = false

    form.addEventListener("submit", (event) => {
      event.preventDefault()
      submitted = true
    })
    const event = new window.Event("change",{})
    input.dispatchEvent(event)
    assert(submitted)
  }).test("<select> 'input' event does not submit the form", ({window,document,assert}) => {

    const form   = document.getElementById("form-1")
    const select = form.querySelector("select")

    let submitted = false

    form.addEventListener("submit", (event) => {
      event.preventDefault()
      submitted = true
    })
    const event = new window.Event("input",{})
    select.dispatchEvent(event)
    assert(!submitted)
  }).test("<textarea> 'input' event does not submit the form", ({window,document,assert}) => {

    const form     = document.getElementById("form-1")
    const textarea = form.querySelector("textarea")

    let submitted = false

    form.addEventListener("submit", (event) => {
      event.preventDefault()
      submitted = true
    })
    const event = new window.Event("input",{})
    textarea.dispatchEvent(event)
    assert(!submitted)
  }).test("<input> 'input' event does not submit the form", ({window,document,assert}) => {

    const form  = document.getElementById("form-1")
    const input = document.getElementById("input-1")

    let submitted = false

    form.addEventListener("submit", (event) => {
      event.preventDefault()
      submitted = true
    })
    const event = new window.Event("input",{})
    input.dispatchEvent(event)
    assert(!submitted)
  }).test("'change' event for element related to another form does nothing", ({window,document,assert}) => {

    const form1 = document.getElementById("form-1")
    const form2 = document.getElementById("form-1")
    const input = document.getElementById("input-2")

    let submitted1 = false
    let submitted2 = false

    form1.addEventListener("submit", (event) => {
      event.preventDefault()
      submitted1 = true
    })
    form2.addEventListener("submit", (event) => {
      event.preventDefault()
      submitted2 = true
    })
    const event = new window.Event("input",{})
    input.dispatchEvent(event)
    assert(!submitted1)
    assert(!submitted2)
  })
})
