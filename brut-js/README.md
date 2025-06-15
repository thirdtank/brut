# brut-js

## Utility Custom Elements and JS for BrutRB

This provides utility custom elements for use in a BrutRB-powered app, as well as a rudimentary testing system for testing custom
elements.

## Install

```
npm install brut-js
```

If you want to write tests for custom elements, you must also install JSDOM and Mocha:

```
npm install --save-dev jsdom mocha
```

## Using Custom Elements

The simplest way is to import them all and define them:

```
import { BrutCustomElements } from "brut-js"
document.addEventListener("DOMContentLoaded", () => {
  BrutCustomElements.define()
})
```

See the jsdocs for what elements are available.

## Testing of Custom Elements

This library contains rudimentary support for testing custom elements using [jsdom](https://github.com/jsdom/jsdom). It attempts to
use the elements as they would in a real browser, and your tests and assertions should interact with the elements using the DOM and
not directly.

A simple example is [the test for `BrutAutosubmit`/`<brut-automsubmit>`](./specs/BrutAutosubmit.spec.js), which enables any form
element to automatically submit the form it's a part of:

```html
<form>
  <brut-autosubmit>
    <input type="text">
  </brut-autosubmit>
  <button>Submit</button>
</form>
```

When the `<input>` above dispatches a "change" event, the `<form>` is submitted.  You can see in the test file that each test locates
the form and the input, dispatches an event from that input, then checks to see if the form was submitted, all using the browser's
APIs.

### Testing Your Custom Elements

1. Set up Mocha

   ```
   npm install --save-dev mocha
   ```
2. Create a location for your tests:

   ```
   mkdir specs/js # can be anything
   ```
3. Create a tautoloigical test to ensure your setup is working:

   ```
   // specs/js/canary.spec.js
   import { withHTML } from "../src/testing/index.js"
   describe("<my-custom-element>", () => {
     withHTML(`
       <my-custom-element>OK</my-custom-element>
     `).test("Tests work", ({document,assert}) => {
        const element = document.querySelector("my-custom-element")
        assert.equal(element.textContent,"OK")
     })
   })
   ```
4. Run mocha:

   ```
   npx mocha specs/js --extension spec.js --recursive
   ```

## Development

1. Install Docker
1. Set up your dev environment:

   ```
   dx/build
   ```
1. Start the dev environment

   ```
   dx/start
   ```
1. In another terminal, set everything up

   ```
   dx/exec bin/setup
   ```
1. Run all tests

   ```
   dx/exec bin/ci
   ```
1. Run a single test

   ```
   dx/exec npm run bundle
   dx/exec npm run test:one specs/File.spec.js
   ```

Remember to run `npm run bundle` any time you change files in `src`, as the tests bring in the code via a bundle produced by that
task.
