import { withHTML } from "./SpecHelper.js"

describe("<brut-i18n-translation>", () => {
  withHTML(`
    <brut-i18n-translation key="greeting" value="Hello %{username}"></brut-i18n-translation>
  `).test("Produces a translation", ({document,assert}) => {
    const element = document.querySelector("brut-i18n-translation")
    const translation = element.translation({username: "Pat"})
    assert.equal(translation,"Hello Pat")
  }).test("Ignores replacements not in the translation", ({document,assert}) => {
    const element = document.querySelector("brut-i18n-translation")
    const translation = element.translation({username: "Pat", email: "pat@example.com"})
    assert.equal(translation,"Hello Pat")
  }).test("Missing replacements raise an error", ({document,assert}) => {
    const element = document.querySelector("brut-i18n-translation")
    const code = () => { element.translation() }
    assert.throws(code,/reading 'username'/)
  })
})
