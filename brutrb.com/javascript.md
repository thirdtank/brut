# JavaScript

Brut provides basic bundling using [esbuild](https://esbuild.github.io/).  Brut does not support nor prevent the
use of any front-end framework.  Brut does, however, include [Brut-JS], a lightweight library of HTML custom
elements and utility code.  These elements can provide a fair bit of front-end functionality using progressive
enhancement without the need for a framework.

## Overview

### Managing Your App's JavaScript

All your app's JavaScript lives in `app/src/front_end/js`, or in modules you bring in via `package.json`.  Brut
will *bundle* all of that up into a single `.js` file that is served up with your app.  Brut does this by using
esbuild, a stable and standardized tool for bundling JavaScript.

The way esbuild works is to be given an *entry point* that requires, or transitively requires, all of your
JavaScript by using ES6 modules. `app/src/front_end/js/index.js` is the entry point for your app.

For example, if you have a `Widget` class that uses a `Status` class, and you also use the third party library
"foobar", here is how all the files would look.

First, `package.json` (in your app's root) would include `"foobar"` (and it must set `"type"` to `"module"`):

```json {2,5}
{
  "name": "your-app",
  "type": "module",
  "license": "UNLICENSED",
  "dependencies": {
    "foobar": "^0.0.11"
  },
  "devDependencies": {
    "chokidar-cli": "^3.0.0",
    "esbuild": "^0.20.2",
    "jsdom": "^25.0.1",
    "mocha": "^10.7.3",
    "playwright": "^1.50.1"
  },
}
```

Next, `app/src/front_end/js/index.js` would import both `"foobar"` and `"Widget"`:

```javascript
import { foobar } from "foobar"
import Widget from "./Widget"

// ...
```

Notice that "foobar", since it's brought in as a third party dependency, is imported without a `./`.  Be careful
here!  Every third party library has a different syntax for how to import whatever it is or does. Consult the
documentation of each third party library you wish to import.

The second `import` uses a `./` because it's importing a file in `app/src/front_end/js` namely `Widget.js`.  Be
careful here, too, as you must be sure to `export` the right thing.  Here's what `app/src/front_end/js/Widget.js`
might look like:

```javascript
import Status from "./extra/Status"

class Widget {
  status = new Status()
}

export default Widget
```

Note that we import `Status` here.  Unlike Ruby, ES6 modules requires each class that references a class to
import it explicitly.  Also notice that we do `export default Widget`, which allows `import Widget` to work.

Finally, `app/src/front_end/extra/Status.js` looks like so:

```javascript
class Status {
}
export default Status
```

When `bin/build-assets` runs, esbuild will use `app/src/front_end/js/index.js` as its *entry point*, and will
bundle both `Widget.js` and the "foobar" library.  When it bundles `Widget.js`, it will see that it imports
`extra/Status.js` and bundle that, too.

This bundle can be included in your app by ensuring this is in your layout:

```ruby {5}
def view_template
  doctype
  html(lang: "en") do
    head do
      script(defer: true, src: asset_path("/js/app.js"))
      # ...
```

The `asset_path` helper takes a logical path—`/js/app.js`—and returns the actual path the browser can use.  More
details on this can be found in [assets](/assets).

### Using Brut-JS

By default, your app is set up to use Brut-JS, although you can remove it by removing a few lines of code.
Here's what `app/src/front_end/js/index.js` looks like initially:

```javascript
import { BrutCustomElements } from "brut-js"

document.addEventListener("DOMContentLoaded", () => {
  BrutCustomElements.define()
})
``` 

A custom element must be explicitly defined to allow it to work.  While you can define Brut's custom elements individually, the `define` method on `BrutCustomElements` is set up to define them all for you.  Brut-JS uses standard HTML custom elements. These should interoperate with any framework code you have, and should remain inert if you don't use them.

Given this setup, you can use any of the elements in your templates.  `Brut::FrontEnd::Component`—the base class
for all HTML-generation in a Brut app—configures Phlex to use these custom elements.  For example, you can
confirm the submission of any form like so:

```ruby
def view_template
  form do
    input type: "text", name: "name"
    brut_confirm_submit message: "Are you sure?" do
      button { "Submit" }
    end
  end
end
```

> [!WARNING]
> You can remove Brut-JS entirely, but several features won't be available if you do. Locale Detection,
> localized client-side constraint violation messaging, and client-side observability won't work.

## Testing

Client-side behavior is best tested with end-to-end tests, however you can simplify your end-to-end tests by
creating unit tests of your custom elements.  Brut-JS provides support for this. TBD LINK.

## Recommended Practices

Brut encourages you to use HTML custom elements as progressive enhancements over server-generated views.  This
sort of client-side code will age well.  The toolchain and dependencies are minimal, so you will not have to
worry too much about code written this way.

It *will* be lower level and more verbose than existing frameworks.  We would argue that it is not significantly
more difficult and the sustainability is worth it.

## Technical Notes

> [!IMPORTANT]
> Technical Notes are for deeper understanding and debugging. While we will try to keep them up-to-date with changes to Brut's
> internals, the source code is always more correct.

_Last Updated May 7, 2025_

Currently, Brut only supports a single entry point and bundle.  This could be easily made more flexible if there
is a desire to finely tweak the JavaScript loaded on specific pages.

Brut also does not expose any esbuild configuration.  This could be provided in the future, but for now, it is
hard-coded.
