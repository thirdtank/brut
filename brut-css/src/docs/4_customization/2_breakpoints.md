## Breakpoints / Responsive Design Customization

There are two ways to control the available breakpoints and thus which classes are available for responsive design. You can
change which bundle of BrutCSS you use, or you can build your own bundle.

### Selecting a Bundle

BrutCSS provides three `.css` files depending on what you need:

* `brut.css` - the largest file with all the classes, plus `-m`, `-l`, and `-ns`, for medium, large and not-small screens, respectively.
* `brut-ns-only.css` - the second largest file with all the classes, plus the not-small (`-ns`) classes.  This provides a
roughtly "mobile" and "desktop" breakpoint system.
* `brut-thin.css` - the smallest file provides only the classes, with no breakpoints.


### Configuring Your Own Bundle

BrutCSS is built via the command line app in `src/js/build.js`.

```
> node src/js/build.js -h
usage: build.js [options]

OPTIONS

  -i/--input                    - Input .css to process
  -m/--media-query-config       - Specialized .css describing the media queries to support in the output
  -p/--pseudo-class-config      - Specialized .css describing the pseudo classes to support in the output
  -o/--output                   - Output .css (this is what your app will use)
  -d/--docs-dir                 - path to generate documentation
  -t/--docs-template-source-dir - path where doc templates live
```

By checking out this repo, you can create your own specialized version of BrutCSS by modifying the file used for the
`--media-query-config` option.

This file is a `.css` file that specifies one or more `@media` queries, each requiring a specialized comment.  Here is the
one used to build `brut.css`:

```
/* Not-small screens, essentially anything that is likely not a mobile device.
 * @suffix ns
 */
@media screen and (min-width: 30em) {
}
/* Medium-sized screens.
 * @suffix m
 */
@media screen and (min-width: 30em) and (max-width: 60em) {
}
/* Large screens.
 * @suffix l
 */
@media screen and (min-width: 60em) {
}
```

`bundle.js` will process all rules in `src/css` and then duplicate them for each `@media` query in the file.  Each `@media`
query **must** have a `@suffix` tag in its doc comment.  This tag is used to name the duplicated class.  This is how `db`
becomes `db-ns` or `fs-3` becomes `fs-3-l`.

You can create your own file that uses different values for `min-width` or even different `@media` queries entirely:

```
/* Dark mode.
 * @suffix dm
 * /
 @media (prefers-color-scheme dark) {
 }
```

Note that currently, this will duplicate *all* of BrutCSS's classes.  This may not be what you want.



