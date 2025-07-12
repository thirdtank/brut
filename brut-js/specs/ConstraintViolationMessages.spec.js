import { withHTML } from "./SpecHelper.js"

describe("<brut-cv-messages>", () => {
  withHTML(`
    <brut-i18n-translation key="cv.cs.patternMismatch" value="%{field} does not match the pattern"></brut-i18n-translation>
    <brut-i18n-translation key="cv.cs.rangeOverflow" value="%{field} is above the range"></brut-i18n-translation>

    <brut-cv-messages input-name="some-field"></brut-cv-messages>
  `).test("Inserts constraint violation messages based on validity state", ({document,assert}) => {
    const element = document.querySelector("brut-cv-messages")

    const validityState = {
      patternMismatch: true,
      rangeOverflow: true,
      customError: true,
    }
    const inputName = "some-field"

    element.createMessages({validityState,inputName})

    assert.equal(element.querySelectorAll("brut-cv").length,2)
    assert.match(element.textContent,new RegExp("This field does not match the pattern","m"))
    assert.match(element.textContent,new RegExp("This field is above the range","m"))

    element.clearClientSideMessages()
    assert.equal(element.textContent,"")
  })

})
