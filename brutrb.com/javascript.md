# JavaScript

Brut provides basic bundling using [esbuild](https://esbuild.github.io/).  Brut does not support nor prevent the
use of any front-end framework.  Brut does, however, include [BrutJS](/brut-js), a lightweight library of HTML custom
elements and utility code.  These elements can provide a fair bit of front-end functionality using progressive
enhancement without the need for a framework.

## Overview

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

## Testing

Client-side behavior is best tested with end-to-end tests, however you can simplify your end-to-end tests by
creating unit tests of your custom elements.  BrutJS provides support for this. TBD LINK.

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
