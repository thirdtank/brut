import { withHTML } from "./SpecHelper.js"

describe("<brut-ajax-submit>", () => {
  withHTML(`
    <form action="http://example.net/foo" method="POST">
      <input required type="text" name="some-text">
      <input required type="number" name="some-number">
      <brut-ajax-submit submitted-lifetime="10">
        <button>Submit</button>
      </brut-ajax-submit>
    </form>
  `).onFetch( "/foo", [
    { then: { status: 200, text: "<div>some html</div>" }},
  ]
  ).test("submits the form, setting various attributes during the lifecycle", 
         ({document,assert,fetchRequests,waitForSetTimeout,readRequestBodyIntoString}) => {

    const element = document.querySelector("brut-ajax-submit")
    const button  = element.querySelector("button")
    const text    = document.querySelector("input[name=some-text]")
    const number  = document.querySelector("input[name=some-number]")

    let okReceived = false
    let detailReceived = null
    element.addEventListener("brut:submitok", (event) => {
      okReceived = true
      detailReceived = event.detail
    })

    text.value   = "Some Text"
    number.value = "11"

    button.click()
    assert(element.getAttribute("requesting") != null)

    const promises = fetchRequests.
      filter( (fetchRequest) => fetchRequest.promiseReturned ).
      map( (fetchRequest) => fetchRequest.promiseReturned )

    return Promise.all(promises).then( () => {
      assert(okReceived)
      assert(detailReceived)
      assert.equal(detailReceived.body.innerHTML,"<div>some html</div>")
      assert(element.getAttribute("requesting") == null)
      assert(element.getAttribute("submitted") != null)
      waitForSetTimeout(11).then( () => {
        assert(element.getAttribute("submitted") == null)
        return readRequestBodyIntoString(fetchRequests[0]).then( (string) => {
          const params = new URLSearchParams(string)
          assert.equal(params.get("some-text"),"Some Text")
          assert.equal(params.get("some-number"),"11")
        })
      })

    })
  }).test("does not submit the form if it's invalid", ({document,assert,fetchRequests}) => {

    const form    = document.querySelector("form")
    const element = form.querySelector("brut-ajax-submit")
    const button  = element.querySelector("button")
    const text    = form.querySelector("input[name=some-text]")
    const number  = form.querySelector("input[name=some-number]")

    let okReceived = false
    element.addEventListener("brut:submitok", (event) => {
      okReceived = true
    })

    const isValid = form.reportValidity()
    assert(!isValid)

    button.click()

    assert.equal(fetchRequests.length,0)
    assert(!okReceived)
  })
  withHTML(`
    <form action="http://example.net/foo" method="POST">
      <input required type="text" name="some-text">
      <input required type="number" name="some-number">
      <brut-ajax-submit submitted-lifetime="10">
        <button>Submit</button>
      </brut-ajax-submit>
    </form>
  `).onFetch( "/foo", [
    { then: { status: 500 }},
    { then: { status: 200 }},
  ]
  ).test("submits the form after a retry",
        ({document,assert,fetchRequests,waitForSetTimeout,readRequestBodyIntoString}) => {
    const element = document.querySelector("brut-ajax-submit")
    const button  = element.querySelector("button")
    const text    = document.querySelector("input[name=some-text]")
    const number  = document.querySelector("input[name=some-number]")

    let okReceived = 0
    element.addEventListener("brut:submitok", () => {
      okReceived++
    })

    text.value   = "Some Text"
    number.value = "11"

    button.click()
    return waitForSetTimeout(5).then( () => {

      const promises = fetchRequests.
        filter( (fetchRequest) => fetchRequest.promiseReturned ).
        map( (fetchRequest) => fetchRequest.promiseReturned )

      return Promise.all(promises).then( () => {
        assert.equal(okReceived,1)
        return readRequestBodyIntoString(fetchRequests[1]).then( (string) => {
          const params = new URLSearchParams(string)
          assert.equal(params.get("some-text"),"Some Text")
          assert.equal(params.get("some-number"),"11")
        })
      })
    })
  })
  withHTML(`
    <form action="http://example.net/foo" method="POST">
      <input required type="text" name="some-text">
      <input required type="number" name="some-number">
      <brut-ajax-submit submitted-lifetime="10" max-retry-attempts=2>
        <button>Submit</button>
      </brut-ajax-submit>
    </form>
  `).onFetch( "/foo", [
    { then: { status: 500 }},
    { then: { status: 500 }},
    { then: { status: 500 }},
  ]
  ).test("when too many failures, submits the form the old-fashioned way", ({document,assert,fetchRequests, waitForSetTimeout}) => {
    const form    = document.querySelector("form")
    const element = form.querySelector("brut-ajax-submit")
    const button  = element.querySelector("button")
    const text    = form.querySelector("input[name=some-text]")
    const number  = form.querySelector("input[name=some-number]")

    let okReceived = 0
    element.addEventListener("brut:submitok", () => {
      okReceived++
    })

    text.value   = "Some Text"
    number.value = "11"

    let submitted = false
    form.addEventListener("submit", (event) => {
      event.preventDefault()
      submitted = true
    })

    button.click()
    return waitForSetTimeout(50).then( () => {

      const promises = fetchRequests.
        filter( (fetchRequest) => fetchRequest.promiseReturned ).
        map( (fetchRequest) => fetchRequest.promiseReturned )

      return Promise.all(promises).then( () => {
        assert.equal(okReceived,0)
        assert(submitted)
      })
    })
  })
  withHTML(`
    <form action="http://example.net/foo" method="POST">

      <input required type="text" name="some-text">
      <brut-cv-messages input-name="some-text">
        <brut-cv input-name="some-text">
        A client-side-error
        </brut-cv>
        <brut-cv server-side input-name="some-text">
        A previous server-side-error
        </brut-cv>
      </brut-cv-messages>

      <input required type="number" name="some-number">
      <brut-cv-messages input-name="some-number">
      </brut-cv-messages>

      <brut-ajax-submit submitted-lifetime="10">
        <button>Submit</button>
      </brut-ajax-submit>
    </form>
  `).onFetch( "/foo", [
    {
      then: {
        status: 422,
        text: `
<brut-cv input-name="some-text">
A sever-side error
</brut-cv>
<brut-cv input-name="some-text">
Another sever-side error
</brut-cv>
<brut-cv input-name="some-other-text">
Irrelevant server-side error
</brut-cv>
<brut-cv>
Error that should be ignored
</brut-cv>
<div>element that should be ignored</div>
        `
      }
    },
  ]
  ).test("when we get a 422, parses the result from the server and inserts them into the DOM, event detail is null", ({document,window,assert,fetchRequests,waitForSetTimeout}) => {
    const form    = document.querySelector("form")
    const element = form.querySelector("brut-ajax-submit")
    const button  = element.querySelector("button")
    const text    = form.querySelector("input[name=some-text]")
    const number  = form.querySelector("input[name=some-number]")

    let okReceived = false
    let submittedInvalidReceived = false
    let submittedInvalidDetail = "not null"
    element.addEventListener("brut:submitok", () => {
      okReceived = true
    })
    element.addEventListener("brut:submitinvalid", (event) => {
      submittedInvalidReceived = true
      submittedInvalidDetail = event.detail
    })

    text.value   = "Some Text"
    number.value = "11"

    button.click()
    return waitForSetTimeout(5).then( () => {

      const promises = fetchRequests.
        filter( (fetchRequest) => fetchRequest.promiseReturned ).
        map( (fetchRequest) => fetchRequest.promiseReturned )

      return Promise.all(promises).then( () => {
        assert(!okReceived)
        assert( submittedInvalidReceived)
        assert(!submittedInvalidDetail)
        const textFieldErrors = form.querySelectorAll("brut-cv-messages[input-name='some-text'] brut-cv")
        assert.equal(3,textFieldErrors.length) // prevous client-side and 2 new server-side
        const serverSideTextFieldErrors = form.querySelectorAll("brut-cv-messages[input-name='some-text'] brut-cv[server-side]")
        assert.equal(2,serverSideTextFieldErrors.length)

        let error = Array.from(textFieldErrors).find( (e) => e.textContent.trim() == "A sever-side error" )
        assert(error)
        error = Array.from(textFieldErrors).find( (e) => e.textContent.trim() == "Another sever-side error" )
        assert(error)
        error = Array.from(textFieldErrors).find( (e) => e.textContent.trim() == "A previous sever-side-error" )
        assert(!error) // should've been cleared
        error = Array.from(textFieldErrors).find( (e) => e.textContent.trim() == "A client-side-error" )
        assert(error)

        const numberFieldErrors = form.querySelectorAll("brut-cv-messages[input-name=some-number] brut-cv")
        assert.equal(0,numberFieldErrors.length)

        assert(text.validity.customError)
        assert(!number.validity.customError)

        text.dispatchEvent(new window.Event("change"))
        assert(!text.validity.customError)
      })
    })
  })
  withHTML(`
    <form action="http://example.net/foo" method="POST">

      <input required type="text" name="some-text">
      <brut-cv-messages input-name="some-text">
        <brut-cv input-name="some-text">
        A client-side-error
        </brut-cv>
        <brut-cv server-side input-name="some-text">
        A previous server-side-error
        </brut-cv>
      </brut-cv-messages>

      <input required type="number" name="some-number">
      <brut-cv-messages input-name="some-number">
      </brut-cv-messages>

      <brut-ajax-submit submitted-lifetime="10" no-server-side-error-parsing>
        <button>Submit</button>
      </brut-ajax-submit>
    </form>
  `).onFetch( "/foo", [
    {
      then: {
        status: 422,
        text: `
<brut-cv input-name="some-text">
A sever-side error
</brut-cv>
<brut-cv input-name="some-text">
Another sever-side error
</brut-cv>
<brut-cv input-name="some-other-text">
Irrelevant server-side error
</brut-cv>
<brut-cv>
Error that should be ignored
</brut-cv>
<div>element that should be ignored</div>
        `
      }
    },
  ]
  ).test("when we get a 422, does not parse the results, but includes them in the detail", ({document,window,assert,fetchRequests,waitForSetTimeout}) => {
    const form    = document.querySelector("form")
    const element = form.querySelector("brut-ajax-submit")
    const button  = element.querySelector("button")
    const text    = form.querySelector("input[name=some-text]")
    const number  = form.querySelector("input[name=some-number]")

    let okReceived = false
    let submittedInvalidReceived = false
    let submittedInvalidDetail = null
    element.addEventListener("brut:submitok", () => {
      okReceived = true
    })
    element.addEventListener("brut:submitinvalid", (event) => {
      submittedInvalidReceived = true
      submittedInvalidDetail = event.detail
    })

    text.value   = "Some Text"
    number.value = "11"

    button.click()
    return waitForSetTimeout(5).then( () => {

      const promises = fetchRequests.
        filter( (fetchRequest) => fetchRequest.promiseReturned ).
        map( (fetchRequest) => fetchRequest.promiseReturned )

      return Promise.all(promises).then( () => {
        assert(!okReceived)
        assert( submittedInvalidReceived)
        assert.equal(submittedInvalidDetail.body.children.length,5)
        const textFieldErrors = form.querySelectorAll("brut-cv-messages[input-name='some-text'] brut-cv")
        assert.equal(2,textFieldErrors.length) // what was initially rendered

      })
    })
  })
})
