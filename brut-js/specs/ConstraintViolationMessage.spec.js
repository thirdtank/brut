import { withHTML } from "./SpecHelper.js"

describe("<brut-cv>", () => {
  withHTML(`
    <brut-i18n-translation key="problem" value="%{field} has a problem"></brut-i18n-translation>

    <brut-cv input-name="some-field" key="problem"></brut-cv>
  `).test("Inserts using 'this field' as the placeholder", ({document,assert}) => {
    const element = document.querySelector("brut-cv")
    assert.equal(element.textContent,"This field has a problem")
  })

  withHTML(`
    <brut-i18n-translation key="problem"       value="%{field} has a problem"></brut-i18n-translation>
    <brut-i18n-translation key="cv.this_field" value="THAT FIELD"></brut-i18n-translation>

    <brut-cv input-name="some-field" key="problem"></brut-cv>
  `).test("Inserts using the this_field key as the placeholder", ({document,assert}) => {
    const element = document.querySelector("brut-cv")
    assert.equal(element.textContent,"THAT FIELD has a problem")
  })

  withHTML(`
    <brut-i18n-translation key="problem"                     value="%{field} has a problem"></brut-i18n-translation>
    <brut-i18n-translation key="cv.this_field"               value="THAT FIELD"></brut-i18n-translation>
    <brut-i18n-translation key="cv.fe.fieldNames.some-field" value="Some Field"></brut-i18n-translation>

    <brut-cv input-name="some-field" key="problem"></brut-cv>
  `).test("Inserts using the this_field key as the placeholder", ({document,assert}) => {
    const element = document.querySelector("brut-cv")
    assert.equal(element.textContent,"Some Field has a problem")
  })
})
