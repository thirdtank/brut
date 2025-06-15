import { withHTML } from "./SpecHelper.js"

describe("<brut-message>", () => {
  withHTML(`
    <brut-i18n-translation key="greeting" value="Hello Everyone!"></brut-i18n-translation>
    <brut-message key="greeting"></brut-message>
    <brut-message key="non-existent"></brut-message>
  `).test("Inserts the translation", ({document,assert}) => {
    const element = document.querySelector("brut-message[key=greeting]")
    assert.equal(element.textContent,"Hello Everyone!")
  }).test("Does nothing if the key is not found", ({document,assert}) => {
    const element = document.querySelector("brut-message[key=non-existent]")
    assert.equal(element.textContent,"")
  })
})
