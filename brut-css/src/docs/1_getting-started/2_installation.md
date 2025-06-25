## Installation

BrutCSS is bundled with BrutRB, however you can install it via NPM:

    npm install brut-css

From there, you can use `@import` to bring it into your app:

    @import "brut-css/dist/brut.css";

You can also try it without installing by use `unpkg.com`:

    <link rel="stylesheet"
          href="https://unpkg.com/brut-css/dist/brut.css"/>

**Note** the distributed files *are already minified*.

### Other Files

`brut.css` includes four breakpoints. You may want only 2, or only 1:

* `brut.css` - default, "not small", "medium", and "large" (most features)
* `brut-ns-only.css` - default and "not small"
* `brut-thin.css` - default only (smallest)

