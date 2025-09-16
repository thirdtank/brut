import { withHTML } from "./SpecHelper.js"

describe("<brut-toast>", () => {
  withHTML(`
    <div>
     <brut-i18n-translation key="toast.saved" value="Save successful"></brut-i18n-translation>
     <brut-toast show-warnings>
       <div>
         <output><span>Message here</span></output>
         <button>Close</button>
       </div>
       <button>Close</button>
     </brut-toast>
   </div>
  `).test("setting the key shows the message, then it's removed when closed", ({window,document,assert}) => {

    const toast = document.querySelector("brut-toast")
    assert(toast, "brut-toast element should be present")

    toast.setAttribute("key", "toast.saved")
    const output = toast.querySelector("output")
    assert.equal(output.textContent.trim(), "Save successful")
    const message = output.querySelector("brut-message")
    assert(message, "brut-message should be present")
    console.log(message.outerHTML)
    assert.equal(message.getAttribute("role"), "status")
    assert.equal(message.getAttribute("aria-live"), "polite")
    assert.equal(message.getAttribute("aria-atomic"), "true")

    const button = toast.querySelector("button")
    button.click()
    assert.equal(toast.getAttribute("key"), null)
  })
})
