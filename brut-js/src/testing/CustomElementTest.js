import DOMCreator from "./DOMCreator.js"
import assert from "assert"
/**
 * The class that implements a test case.  Typically, an instance of this is created for you and you call `test` on that to write your
 * test case.
 * @memberof testing
 */
class CustomElementTest {
  constructor(html, queryString, assetMetadata) {
    this.html          = html
    this.queryString   = queryString
    this.fetchBehavior = {}
    this.assetMetadata = assetMetadata
  }

  /**
   * Configure a query string to be present when the custom elements are defined and connected.
   */
  andQueryString(queryString) {
    this.queryString = queryString
    return this
  }

  /**
   * Configure behavior when #{link external:fetch} is called, since it's not implemented by JSDom or NodeJS.
   *
   * @param {String} url - the URL that is expected. This should be a relative URL, as that is all that is currently supported. This
   * URL must match exactly to a `fetch` call.
   * @param {Object} behavior - an object describing what you want to happen when `url` is fetched.  This currently supports only a
   * few rudimentary behaviors:
   * * `{then: { ok: { text: "some text" } } }` - This will return an "ok" response whose body is the given text, available only as
   * text.
   * * `{then: { status: XXX, text: "some text" }}` - This will return the given http status, with `ok` as true if it's 2xx or 3xx. If `text` is given, that will be available as text only.
   */
  onFetch(url,behavior) {
    if (!this.fetchBehavior[url]) {
      this.fetchBehavior[url] = {
        numCalls: 0,
        responses: [],
      }
    }
    if (behavior instanceof Array) {
      behavior.forEach( (b) =>  {
        this.fetchBehavior[url].responses.push(b)
      })
    }
    else {
      this.fetchBehavior[url].responses.push(behavior)
    }
    return this
  }

  /** Comment out a test without using code comments */
  xtest() {
    return this
  }


  /** Declare a test to run with the previously-defined HTML, query string, and fetch behavior.
   *
   * @param {String} description - a description of the test.
   * @param {testCodeCallback} testCode - a function containing the code for your test.
   */
  test(description,testCode) {
    it(description, () => {
      const domCreator = new DOMCreator(this.assetMetadata)
      const dom = domCreator.create({
        html: this.html,
        queryString: this.queryString
      })
      const fetchRequests = []

      dom.window.Request = Request
      dom.window.fetch = (request) => {
        const url = new URL(request.url)
        const path = url.pathname + url.search
        const behaviors = this.fetchBehavior[path]
        if (!behaviors) {
          throw `fetch() called with ${path}, which was not configured`
        }
        if (behaviors.numCalls > behaviors.responses.length) {
          throw `fetch() called ${behaviors.numCalls} times, but we only have ${behaviors.response.length} responses configured`
        }
        const behavior = behaviors.responses[behaviors.numCalls]
        behaviors.numCalls++

        let promise = null

        if (behavior.then) {
          if (behavior.then.ok) {
            if (behavior.then.ok.text) {
              const response = {
                ok: true,
                text: () => {
                  return Promise.resolve(behavior.then.ok.text)
                }
              }
              promise = Promise.resolve(response)
            }
            else {
              throw `unknown fetch behavior: expected then.ok.text: ${JSON.stringify(behavior)}`
            }
          }
          else if (behavior.then.status) {
            let ok = false
            if ((behavior.then.status >= 200) && (behavior.then.status < 400) ){
              ok = true
            }
            const response = {
              ok: ok,
              status: behavior.then.status,
                text: () => {
                  return Promise.resolve(behavior.then.text)
                }
            }
            promise = Promise.resolve(response)
          }
          else {
            throw `unknown fetch behavior: expected then.ok or then.status: ${JSON.stringify(behavior)}`
          }
        }
        else {
          throw `unknown fetch behavior: expected then: ${JSON.stringify(behavior)}`
        }
        request.promiseReturned = promise
        fetchRequests.push(request)
        return promise
      }

      const window = dom.window
      const document = window.document
      let returnValue = null
      return new Promise( (resolve, reject) => {
        dom.window.addEventListener("load", () => {
          try {
            const paramsGivenToTest = {
              window,
              document,
              assert,
              fetchRequests,
              waitForSetTimeout: this.#waitForSetTimeout,
              readRequestBodyIntoJSON: this.#readRequestBodyIntoJSON,
              readRequestBodyIntoString: this.#readRequestBodyIntoString,
            }
            returnValue = testCode(paramsGivenToTest)
            if (returnValue) {
              resolve(returnValue)
            }
            else {
              resolve()
            }
          } catch (e) {
            reject(e)
          }
        })
      })
    })
    return this
  }

  /** Used to wait for a few milliseconds before performing further assertions.
   * This can be useful when a custom element has `setTimeout` calls
   */
  #waitForSetTimeout = (ms) => {
    return new Promise( (resolve) => {
      setTimeout(resolve,ms)
    })
  }

  /**
   * Given a fetch request (available via `fetchRequests` passed to your test), turn the body into JSON
   * and return a promise with the JSON.  To use this in a test, you must include your assertions inside
   * the `then` of the returned promise and you *must* return that from your test.
   *
   * @example
   * withHTML(
   *   "<div-makes-a-fetch>"
   * ).onFetch("/foo", { then: { status: 200 }}
   * ).test("a test",({assert,fetchRequests}) => {
   *   assert.equal(fetchRequests.length,1)
   *   return readRequestBodyIntoJSON(fetchRequests[0]).then( (json) => {
   *     assert.equal(json["foo"],"bar")
   *   })
   * })
   */
  #readRequestBodyIntoJSON = (request) => {
    return this.#readRequestBodyIntoString(request).then( (string) => {
      try {
        const json = JSON.parse(string)
        return Promise.resolve(json)
      }
      catch (e) {
        assert(false,`'${string}' could not be parsed as JSON`)
      }
      return Promise.resolve()
    })
  }

  /**
   * Given a fetch request (available via `fetchRequests` passed to your test), turn the body into a string
   * and return a promise with the string.  To use this in a test, you must include your assertions inside
   * the `then` of the returned promise and you *must* return that from your test.
   *
   * @example
   * withHTML(
   *   "<div-makes-a-fetch>"
   * ).onFetch("/foo", { then: { status: 200 }}
   * ).test("a test",({assert,fetchRequests}) => {
   *   assert.equal(fetchRequests.length,1)
   *   return readRequestBodyIntoString(fetchRequests[0]).then( (string) => {
   *     assert.equal(string,"foo")
   *   })
   * })
   */
  #readRequestBodyIntoString = (request) => {
    const reader = request.body.getReader()
    const utf8Decoder = new TextDecoder("utf-8");
    let string = ""
    const parse = ({value,done}) => {
      if (done) {
        return Promise.resolve(string)
      }
      else {
        if (value) {
          string = string + utf8Decoder.decode(value, { stream: true })
        }
        return reader.read().then(parse)
      }
    }
    return reader.read().then(parse)
  }


}
export default CustomElementTest
