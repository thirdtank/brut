## Changing the Design System

Brut's custom properties are documented here. Changing them involves overriding their values using the [custom property syntax](https://developer.mozilla.org/en-US/docs/Web/CSS/CSS_cascading_variables/Using_CSS_custom_properties) supported by browsers:

```
:root {
   --ff-sans: Avenir, sans;
}
```

As long as this appears after you've imported BrutCSS, your overrides will take effect.

Of note, BrutCSS uses `@property` to declare and define all custom properties.  While these are duplicated to a `:root` block
for compatibility, since `@property` cannot use functions for `initial-value`, several values which are semantically derived
from other values are not *actually* so derived.

For example, `--wh-1` is intended to be double the value of `--sp-1`, however this doubling is done offline:

```
@property --sp-1 {
  syntax: "<length>";
  inherits: true;
  initial-value: 0.25rem;
}
@property --wh-1 {
  syntax: "<length>";
  inherits: true;
  initial-value: 0.5rem;
}
```

We mention this so that if you choose to modify the spacing scale, you should also consider updating the width/height scale
to match.

In general, we recommended that you modify either all values in a category or none of them. The source code and documentation
reflect the categorizations.
