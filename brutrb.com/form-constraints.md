# Form Constraint Validations

Aside from simply collecting data and submitting it to the server, form data has
*constraints* that must be validated before data is accepted.  Brut provides support
for both client-side and server-side constraints.

## Overview

When validating form data against its constraints, Brut provides assistance in two
ways:

* Specifying constraint violations that only the server can evaluate.
* Unifying the user experience for both client-side and server-side constraint violations.

### Specifying Constraints

For both client and server-side constraint violations, Brut uses the
`Brut::FrontEnd::Forms::ConstraintViolation` class to represent a specific error on
a specific field. This class is a wrapper around an i18n key, context to generate
that key's messaging, and a flag indicating if the violation is server or client
side.

To specify a server-side constraint violation on a form, call
`server_side_constraint_violation`:

```ruby
form.server_side_constraint_violation(
  input_name: :name,
  key: :name_is_taken
)
```

The `input_name` is the same value you used when creating your form class, and `key`
is an [I18n](/i18n) key that will have `cv.ss` prepended to it (for **c*onstratin **v**iolation, **s**server **s**ide).  Thus, the key in the above example is `"cv.ss.name_is_taken"`.

Brut forms will automatically add client-side constraints based on the value
assigned to the input.  For example, since `name` must be 3 or more characters, this
code would implicitly set `:rangeOverflow` as a client-side constraint violation:

```ruby
form.input(:name).value = "xx"
```

### Accessing Constraints when Generating HTML

`Brut::FrontEnd::Form` provides the method `constraint_violations` to access the
constraints, however we recommend using the
`Brut::FrontEnd::Components::ConstraintViolations` component instead. This component
generates particular markup useful for unifying the UX around constraint violations,
which we'll discuss in a moment.

```ruby {13,16,19}
class NewWidgetPage < AppPage
  include Brut::FrontEnd::Components

  def initialize(form: nil)
    @form = form || NewWidgetForm.new
  end

  private attr_reader :form

  def page_template
    FormTag(for: form) do
      Components::InputTag(form:, input_name: :name)
      Components::ConstraintViolations(form: input_name: :name)

      Components::InputTag(form:, input_name: :quantity)
      Components::ConstraintViolations(form: input_name: :quantity)

      Components::TextareaTag(form:, input_name: :description)
      Components::ConstraintViolations(form: input_name: :description)
    end
  end
end
```

Among other things, `ConstraintViolations` will translate all server-side constraint
violations into the currently selected locale, if there are any.

### Styling Server and Client-Side Constraint Violations

Without any server-side constraint violations, this is the HTML that would be
generated for the "name" input tag:

```html
<input type="text" name="name" required minlength="3">
<brut-cv-messages input-name="name"></brut-cv-messages>
```

`<brut-cv-messages>` is an autonomous custom element that serves two purposes:

* It is part of how client-side constraint violations are shown to the visitor.
* It can be used to target CSS for styling, without the need for `<div>` and `data-` elements. It's more explicitly for constraint violation messaging.

To make `<brut-cv-messages>` work with client-side constraint violations, the
`<form>` must be contained by a `<brut-form>`:

```ruby {2,13}
def page_template
  brut_form do
    FormTag(for: form) do
      Components::InputTag(form:, input_name: :name)
      Components::ConstraintViolations(form: input_name: :name)

      Components::InputTag(form:, input_name: :quantity)
      Components::ConstraintViolations(form: input_name: :quantity)

      Components::TextareaTag(form:, input_name: :description)
      Components::ConstraintViolations(form: input_name: :description)
    end
  end
end
```

`<brut-form>` listens for events from the `<form>` it contains. For an "invalid"
events, it will locate the element relevant to the event, locate its
`<brut-cv-messages>` tag, and insert one `<brut-cv>` tag for each error from the
inputs `ValidityState`.  That may look like so:

```html {3}
<input type="text" name="name" required minlength="3">
<brut-cv-messages input-name="name">
  <brut-cv input-name="name" key="rangeUnderflow"></brut-cv>
</brut-cv-messages>
```

They `key` attribute is for an I18n key that is expected to be on the page inside a
`<brut-i18n-translation>` element.  These are typically included in the [layout](/layouts), and generate HTML like so:

```html
<brut-i18n-translation key="cv.cs.rangeUnderflow"
                       value="%{field} is too short"></brut-i18n-translation>
```

`<brut-cv>` will, whenever its `key` attribute is set or changed, locate the
corrsponding `<brut-i18n-translation>` element, and perform substitution, result in
this HTML:

```html {4}
<input type="text" name="name" required minlength="3">
<brut-cv-messages input-name="name">
  <brut-cv input-name="name" key="rangeUnderflow">
    This field is too short
  </brut-cv>
</brut-cv-messages>
```

Presumably, your layout rendered `<brut-i18n-translation>` tags with the visitor's
chosen locale (which would be the default behavior of the layout included with a new app).

Coming back to the use of `ConstraintViolations`, if there were a server-side
violation, the same general markup is generated:

```html {3,4}
<input type="text" name="name" required minlength="3">
<brut-cv-messages input-name="name">
  <brut-cv server-side>
    This name has already been taken.
  </brut-cv>
</brut-cv-messages>
```

The `server-side` attribute is set, which can help with CSS targeting.

The *last* piece of this puzzle is a solution for the issue where forms that have
not yet been submitted are considered to have invalid values by the browser.
`<brut-form>` will add the `submitted-invalid` attribute to itself whenever form
submission has been prevented by invalid attributes.

This might lead to HTML like so:

```html {1}
<brut-form submitted-invalid>
  <form ...>

    <!-- .. -->

    <input type="text" name="name" required minlength="3">
    <brut-cv-messages input-name="name">
      <brut-cv input-name="name" key="rangeUnderflow">
        This field is too short
      </brut-cv>
    </brut-cv-messages>

    <!-- ... -->

  </form>
</brut-form>
```

This is everything you need to style all constraint violations the same:

```css
/* By default, brut-cv is hidden */
brut-cv {
  display: none;
}

/* brut-cv inside a submitted-invalid
   OR brut-cv from the server ARE shown */
brut-form[submitted-invalid] brut-cv,
brut-cv[server-side] {
  display: block;
  color: red; /* e.g. */
}
```

If JavaScript is not enabled, everything degrades properly, as long as your handler
re-checks the client-side validations (we'll discuss in the next module):

```ruby
def handle
  # This will be true by virtue of the form's
  # values having been set to values that violate
  # one or more client-side violations.
  if @form.constraint_violations?
    # ...
  end
end
```

## Testing

Testing client-side validations must be done with end-to-end tests.  Writing code
like so will work just fine:

```ruby
button = page.locator("brut-form button")
button.click

brut_cv = page.locator("brut-cv-messages[input-name='name'] brut-cv")
expect(brut_cv).to have_text("too short")
```

Playwright will wait for the `brut-cv` containing the text "too short" to appear on
the page, so you should not have any race conditions.

## Recommended Practices

### Utility CSS is Tricky Here

Utility CSS like BrutCSS or TailwindCSS isn't well-suited to targeting elements
based on custom elements or attributes.  You will need to write CSS or need to
create your own utility CSS for these situations.

In our opinion, writing CSS for something like this isn't a big deal as it can
reduce duplcation via the use of custom properties from your CSS library/design
system and it tends to be stable once created.

### Learn to Be OK with the Browser's UX

One complain about client-side constraint violations is that the browser often
provides UX that you cannot control.  This isn't ideal, but it does have the virtue
of being accessible and obvious.  Visitors also really don't care about how ugly it
is as much as you might think.  The utility and accessibility offset is as
worthwhile tradeoff.

## Technical Notes

> [!IMPORTANT]
> Technical Notes are for deeper understanding and debugging. While we will try to keep them up-to-date with changes to Brut's
> internals, the source code is always more correct.

_Last Updated July 6, 2025_

Nothing at this time.
