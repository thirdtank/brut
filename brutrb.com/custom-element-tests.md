# Testing Custom Elements

While simple custom elements can be tested as part of an [end-to-end test](/end-to-end-tests), more
complex custom elements can benefit from a unit test.  Spoiler: this is not going to be pleasant.

## Overview

Brut-JS provides a testing module that uses JSDom to allow you to test your custom elements.  There are
downsides to JSDom, but it's the simplest way to achieve a reasonably-useful unit test.

You can use `bin/scaffold` to create a test, which will create a `.spec.js` file in `specs/front_end/js/`.
Suppose we the custom element `MyElement`:

```
> bin/scaffold custom_element_test app/src/front_end/js/MyElement.js
```

This creates `specs/front_end/js/MyElement.spec.js`:

```javascript
import { withHTML } from "brut-js/testing/index.js"

describe("<some-element>", () => {
  withHTML(`
  <my-element>
  </my-element>
  `).test("description here", ({document,window,assert}) => {
    assert.fail("test goes here")
  })
})
```

`withHTML` creates a JSDom-based document with the given HTML. This HTML is in effect inside the test.
Mock versions of `document` and `window` are passed to the test, and any other functions you need can be
as well, such as `assert`.

The idea is that you use the browser APIs to examine the DOM and assert the behavior of the custom element
(as opposed to interacting with the custom element's class).

Suppose that `my-element` transform text inside it based on the `transform` attribute. By default, it's
`lower`, but can be set to `upper` to lower case or upper case, respectively, the text inside.

This means you'll need three tests, each with a different DOM:

```javascript
import { withHTML } from "brut-js/testing/index.js"

describe("<some-element>", () => {
  withHTML(`
  <my-element>
    Some Text
  </my-element>
  `).test("lower-cases by default", ({document,window,assert}) => {
    // TBD
  })

  withHTML(`
  <my-element transform="lower">
    Some Text
  </my-element>
  `).test("lower-cases explicitly", ({document,window,assert}) => {
    // TBD
  })

  withHTML(`
  <my-element transform="upper">
    Some Text
  </my-element>
  `).test("upper-cases explicitly", ({document,window,assert}) => {
    // TBD
  })
})
```

when the function you give to `test` is executed, the DOM will have been setup, so you can rely on your
custom elements `connectedCallback` having been called.  Assuming the text transformation for `my-element`
occurs in `connectedCallback`, here is how you'd test all three cases:

```javascript {9,10,18,19,27,28}
import { withHTML } from "brut-js/testing/index.js"

describe("<some-element>", () => {
  withHTML(`
  <my-element>
    Some Text
  </my-element>
  `).test("lower-cases by default", ({document,window,assert}) => {
    const element = document.querySelector("my-element")
    assert.equal(element.textContent.trim(),"some text")
  })

  withHTML(`
  <my-element transform="lower">
    Some Text
  </my-element>
  `).test("lower-cases explicitly", ({document,window,assert}) => {
    const element = document.querySelector("my-element")
    assert.equal(element.textContent.trim(),"some text")
  })

  withHTML(`
  <my-element transform="upper">
    Some Text
  </my-element>
  `).test("upper-cases explicitly", ({document,window,assert}) => {
    const element = document.querySelector("my-element")
    assert.equal(element.textContent.trim(),"SOME TEXT")
  })
})
```

You'll notice almost all of this uses the browser APIs you (should :) know and (hopefully :) love.

You can manipulate the DOM inside a test as well, and it should behave as if you are doing it in a
browser.  Note that many browser APIs are synchronous, so you don't have to add `await` before every
single line of code.

Note that all of these test run under NodeJS, which is different from a browser.  This means that code
like `new InputEvent()` will succeed in returning an `InputEvent`, but said object is in no way the
`InputEvent` you'd use in a browser. You must use `window.`:

```javascript
// does not work, but doesn't raise an error either
input.dispatchEvent(new InputEvent("input", {}))        

// works
input.dispatchEvent(new window.InputEvent("input", {}))
```

## Recommended Practices

The custom element test library is *very* basic.  Testing asychronous things like `fetch` is extremely
difficult.  Your best bet is to use these tests for edge cases and error conditions.


## Technical Notes

> [!IMPORTANT]
> Technical Notes are for deeper understanding and debugging. While we will try to keep them up-to-date with changes to Brut's
> internals, the source code is always more correct.

_Last Updated June 13, 2025_

I will be honest with you, this part of Brut needs a lot of work and thinking-through.  It's way to
DSL-tasitc for my tastes, but it does work for some needs.  JSDom is not ideal and requires a lot of hoops
when using events or anything browsers support that it does not.

This is highly likely to change.  My current thinking on addressing the need is to run the tests in a real
browser and to make the test setup and code more like what you'd actually write when using these elements.
