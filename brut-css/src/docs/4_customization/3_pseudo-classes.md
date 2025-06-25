## Pseudo Classes

Brut provides a limited number of pseudo-class selectors.  To change how this works, you must create your own bundle using
`src/js/build.js`.

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
`--pseudo-class-config` option.

This file is a `.css` file that uses proprietary `@`-rules.  The top-level rule is called `@brut-pseudo` and it accepts two
arguments inside parens: the pseudo class being targeted and the prefix to use for the classes targeting it.

Inside this `@-rule`, you can use these `@` rules to describe which classes to target:

* `@brut-classes-with-prefix(«prefix»)` - target all classes that start with the given prefix.
* `@brut-class(«class»)` - target the specific class.
* `@brut-colors` - target the foreground color classes.


Here is the one used to build `brut.css`:

```
@brut-pseudo(hover hover true) {
  @brut-classes-with-prefix(bg-);
  @brut-class(tdu);
  @brut-colors;
}
@brut-pseudo(disabled disabled) {
  @brut-classes-with-prefix(bg-gray);
  @brut-classes-with-prefix(gray-);
}
```

This creates classes that start with `hover-` for:

* All classes starting with `bg-` (which are the background color classes)
* The class `tdu`
* The foreground color classes

This also creates classes starting with `disabled-` for:

* All classes starting with `bg-gray`
* All classes starting with `gray-`

You can create your own file to target the pseudo selectors you want.  For example, if you wanted to target the active state
for only reds and oranges, using the `act-` suffix:

```
@brut-pseudo(active act) {
  @brut-classes-with-prefix(bg-red);
  @brut-classes-with-prefix(red-);
  @brut-classes-with-prefix(bg-orange);
  @brut-classes-with-prefix(orange-);
}
```

Note that this will happend *before* breakpoints are examined, so if you have, say, three configured breakpoints (the deafult), the above configurations will result in four additional classes per class targeted.




