import { withHTML } from "./SpecHelper.js"

describe("<brut-locale-detection>", () => {
  withHTML(`
    <brut-locale-detection timeout-before-ping-ms="0" url="http://example.net/locale"></brut-locale-detection>
  `).onFetch( "/locale", [
    { then: { status: 200 }},
  ]
  ).test("Receives the locale and timeZone from the browser", ({document,assert,fetchRequests,readRequestBodyIntoJSON}) => {

    assert.equal(1,fetchRequests.length)
    return readRequestBodyIntoJSON(fetchRequests[0]).then( (json) => {
      assert.equal(json["locale"],"en-US")
      assert.equal(json["timeZone"],"UTC")
    })
  })
  withHTML(`
    <brut-locale-detection locale-from-server="en-US" timezone-from-server="UTC" timeout-before-ping-ms="0" url="http://example.net/locale"></brut-locale-detection>
  `).test("makes no calls to fetch", ({document,assert,fetchRequests}) => {
    assert.equal(fetchRequests.length,0)
  })
})
