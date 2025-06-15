# CSS

Brut provides basic bundling using [esbuild](https://esbuild.github.io/). You can organize your CSS across
multiple files, and you can bring in third party CSS libraries, as long as they are available from NPM (though you can always just download `.css` files manually)

## Managing Your App's CSS

All your app's CSS lives in `app/src/front_end/css`, or in modules you bring in via `package.json`.  Brut
will *bundle* all of that up into a single `.css` file that is served up with your app.  Brut does this by using
esbuild, a stable and standardized tool for bundling CSS.

The way esbuild works is to be given an *entry point* that requires, or transitively requires, all of your
CSS by using the standard [`@import` directive](https://developer.mozilla.org/en-US/docs/Web/CSS/@import). `app/src/front_end/css/index.css` is the entry point for your app.

> [!NOTE]
> The reason to bundle CSS instead of allowing browsers to manage the `@import`
> directives is to create a single download that is hashed for use with CDNs.  This simplifies 
> deployment and ensures all your CSS is available everywhere.  The trade-off is that you cannot
> easily fine-tune each page's CSS.

Let's see an example.  Let's say you are using the "foobar-css" CSS framework, and have placed some of your CSS in `app/src/front_end/css/pages/HomePage.css`.

First, `package.json` (in your app's root) would include `"foobar-css"`:

```json {6}
{
  "name": "your-app",
  "type": "module",
  "license": "UNLICENSED",
  "dependencies": {
    "foobar-css": "^0.0.11"
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

Next, `app/src/front_end/css/index.css` would import both `"foobar-css"` and `"pages/HomePage.css"`.

```javascript
@import "foobar-css/everything.css";
@import "pages/HomePage.css";
```

In the browser `@import` accepts any URL and will resolve it when the file is loaded.  In Brut, when bundled using esbuild, these strings are relative paths to files in either `node_modules/` or `app/src/front_end/css/`.  Unlike JavaScript imports, you don't need `"./"` to differentiate the two. Also unlike JavaScript imports, these must be the first lines of your `index.css` file or they will be ignored. All imports must come before any CSS.

## Importing Third Party CSS

Because there are so many ways to use NPM modules, it's not common to find reliable documentation on how to use a CSS library you bring in via NPM/`package.json`.

The key to figuring out what to use with `@import` is that the value is relative to `node_modules` and should an actual filename, including path and extension. You can figure this out by looking inside `node_modules` after you've done `bin/setup` (or `npm install`).

Suppose "foobar-css" has this directory structure:

```
node_modules/
  foobar-css/
    css/
      foobar-all.css
      foobar-thin.css
```

To use `foobar-thin.css`, you'd write this `@import` directive:

```css
@import "foobar-css/css/foobar-thin.css";
```

## Using Brut-CSS

By default, Brut includes a lightweight functional CSS library called "brut-css".  It provides a basic design system and single-purpose classes to allow you to quickly prototype or build UIs.  It is similar to TailwindCSS by far far smaller and simpler (and less powered).

It is included so you have something to start with. You can use it by using its various classes like `bg-green-300` and `m-4`, or you can use its provided custom properties like `var(--green-300)` and `var(--sp-4)`.

To remove it, remove this line from `index.css`

```css
@import "brut-css/brut.css"; /* [!code --] */
@import "your/css/here.css";
```

## Using TailwindCSS

TBD

## Technical Notes

> [!IMPORTANT]
> Technical Notes are for deeper understanding and debugging. While we will try to keep them up-to-date with changes to Brut's
> internals, the source code is always more correct.

_Last Updated May 8, 2025_

Currently, Brut only supports a single entry point and bundle.  This could be easily made more flexible if there
is a desire to finely tweak the CSS loaded on specific pages.

Brut also does not expose any esbuild configuration.  This could be provided in the future, but for now, it is
hard-coded.
