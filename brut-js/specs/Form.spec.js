import { withHTML } from "./SpecHelper.js"

describe("<brut-form>", () => {
  withHTML(`
    <brut-form>
      <form>
        <label>
          <input required type="text" name="text">
          <brut-cv-messages input-name="text">
          </brut-cv-messages>
        </label>
        <label>
          <input required type="number" name="number">
          <brut-cv-messages input-name="number">
          </brut-cv-messages>
        </label>
        <input type="submit">Save</input>
        <brut-ajax-submit>
          <button>Save Ajaxily</button>
        </brut-ajax-submit>
      </form>
    </brut-form>
  `).test("sets submitted-invalid on submit with invalid form + updates messages", ({window,document,assert}) => {

    const brutForm         = document.querySelector("brut-form")
    const form             = brutForm.querySelector("form")
    const button           = form.querySelector("input[type=submit]")
    const textFieldLabel   = form.querySelector("label:has(input[type=text])")
    const numberFieldLabel = form.querySelector("label:has(input[type=number])")

    let submitted  = false
    let gotInvalid = false
    let gotValid   = false

    form.addEventListener("submit", (event) => {
      event.preventDefault()
      submitted = true
    })
    brutForm.addEventListener("brut:valid", () => {
      gotValid = true
    })
    brutForm.addEventListener("brut:invalid", () => {
      gotInvalid = true
    })
    assert.equal(brutForm.getAttribute("submitted-invalid"),null)

    button.click()

    assert(!submitted)
    assert(!gotValid)
    assert(gotInvalid)
    assert.equal(brutForm.getAttribute("submitted-invalid"),"")

    let error = textFieldLabel.querySelector("brut-cv[key='cv.cs.valueMissing']")
    assert(error)
    error = numberFieldLabel.querySelector("brut-cv[key='cv.cs.valueMissing']")
    assert(error)

    const textField = textFieldLabel.querySelector("input")
    textField.value = "Some Value"
    textField.dispatchEvent(new window.Event("input"))

    submitted       = false
    gotInvalid      = false
    gotValid        = false

    button.click()

    assert(!submitted)
    assert(!gotValid)
    assert(gotInvalid)
    assert.equal(brutForm.getAttribute("submitted-invalid"),"")

    error = textFieldLabel.querySelector("brut-cv[key='cv.cs.valueMissing']")
    assert(!error)
    error = numberFieldLabel.querySelector("brut-cv[key='cv.cs.valueMissing']")
    assert(error)

    const numberField = numberFieldLabel.querySelector("input")
    numberField.value = "99"
    numberField.dispatchEvent(new window.Event("input"))

    submitted       = false
    gotInvalid      = false
    gotValid        = false

    button.click()

    assert(submitted)
  }).test("Works with ajax submissions to keep errors consistent", ({window,document,assert}) => {

    const brutForm         = document.querySelector("brut-form")
    const form             = brutForm.querySelector("form")
    const ajaxSubmit       = form.querySelector("brut-ajax-submit")
    const textFieldLabel   = form.querySelector("label:has(input[type=text])")
    const numberFieldLabel = form.querySelector("label:has(input[type=number])")

    const textField = textFieldLabel.querySelector("input")
    textField.value = "Some Value"
    textField.dispatchEvent(new window.Event("input"))

    const numberField = numberFieldLabel.querySelector("input")
    numberField.value = "99"
    numberField.dispatchEvent(new window.Event("input"))

    let submitted  = false
    let gotInvalid = false
    let gotValid   = false

    form.addEventListener("submit", (event) => {
      event.preventDefault()
      submitted = true
    })
    brutForm.addEventListener("brut:valid", () => {
      gotValid = true
    })
    brutForm.addEventListener("brut:invalid", () => {
      gotInvalid = true
    })

    ajaxSubmit.dispatchEvent(new window.Event("brut:submitinvalid"))

    assert(!submitted)
    assert(!gotValid)
    assert(gotInvalid)

    submitted  = false
    gotInvalid = false
    gotValid   = false

    ajaxSubmit.dispatchEvent(new window.Event("brut:submitok"))

    assert(!submitted)
    assert(gotValid)
    assert(!gotInvalid)
  })
})
