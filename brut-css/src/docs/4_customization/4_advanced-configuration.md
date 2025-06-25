## Advanced Configuration

BrutCSS does not support advanced configuration options directly, however you can clone its repo and use its internal build
system to save a bit of work.

### How BrutCSS is Built

`src/css/index.css` is the root file for all of BrutCSS (the value for `build.js`'s `--input`).  This file uses `@import` to bring in first the custom properties in
`src/css/properties/`, and then each `.css` file.  The aforementioned media query and pseudo class configuration files are
also inputs.

Each `.css` file contains doc comments and some tags (tokens starting with `@`).  These comments and tags define a structure:

* *Categories* group similar concepts. The side nav of this site shows categories like typography or spacing.
* *Scales* or *Groups* are the different available values for the same CSS attribute.  These appear in the right-hand sidebar
on each category page.  Font scale is an example.
* *Property* is a custom property, as defined by the `@property` rule, for example `--ff-sans`, which sets the sans serif
font face.
* *Rules* or *Classes* are CSS classes you'd use in your HTML, for example `fw-4` for a font weight of 400.

When `src/js/build.js` runs, it processes all of this information.  It is based on PostCSS and does the following:

1. `@import` properties are applied to create a single `.css` file
2. For each `@property`, a value in a new `:root` rule is created.  This `:root` rule is added after all `@property` rules, but before any classes.
3. If `--docs-dir` was specified, all the doc comments are read and documentation is produced.
4. The pseudo class configuration is processed and new classes generated.
5. The media query configuration is processed and new classes generated.

The result, as a single `.css` file is output to `--output`.

### Build Your Own BrutCSS

With this information, you can build or enhance your own `.css` file.  The simplest way to do this would be:

1. Clone this repo
2. Add, modify, or remove files in `src/css`
3. Create your own media query or pseudo class files in `config/`
4. Run `build.js`


