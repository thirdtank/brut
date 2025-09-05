# Forms

In HTML, forms are the way data is submit to the server.  Forms attract complexity
since they interact with user experience, data validation, and interaction with a
back-end database.

## Overview

Forms in Brut accomplish three things:

* Forms model the data elements of a `<form>`, including client-side constraints (which Brut can check server-side as well).
* Forms assist in HTML generation, to ensure the HTML elements are consistent and
correct.
* Forms hold data submitted to the server. No need for strong parameters or digging
into a Hash of Whatever.

Since forms can lead to a lot of complexity, this module will stick to the very
basics.  There are several recipes we'll link to that explain more complex
interactions with forms.

### Declaring Form Data/Elements

When you [create a form route](/routes), this imlplies a form class exists to
specify the data:

```ruby
# app/src/app.rb
routes do
  form "new_widget"
end

# app/src/front_end/forms/new_widget_form.rb
class NewWidgetForm < AppForm
end
```

`AppForm` extends `Brut::FrontEnd::Form`, which provides class methods you can use
to declare your form's elements.  Let's say our form has a name (that must be at least 3 characters), a quantity (integer greater than 0), and an optional description.

```ruby
class NewWidgetForm < AppForm
  input :name, minlength: 3
  input :quantity, type: :number, min: 0, step: 1
  input :description, required: true
end
```

`input` declares a form element that will ultimately be handled by an `<input>` or
`<textarea>` tag.  `select` and `radio_button_group` are also avaiable, and are
discussed in recipes.

`input` accepts an input name used for `<input>`'s `name` attribute.  It also
accepts keyword arguments that match the initializer of
`Brut::FrontEnd::Forms::InputDefinition`.  You'll notice those values mirror the
various attributes related to client-side constraint validations, for example
`minlength:` and `pattern:`.

Form elements have some defaults, as described below:

| Declaration | Default Behavior |
|---|---|
| `input :email` | `type: :email` |
| `input :password` | `type: :password` |
| `input :password_confirmation` | `type: :password` |
| `input «any other name»` | `type: :text` |
| `input «name», type: :checkbox` | `required: false` |
| `input «name» type: «not checkbox»` | `required: true` |

### Using Forms to Generate HTML

One reason Brut models forms as classes with declared inputs is that you can then
use an instance of that class to generate HTML.  Brut will generate appropriate
HTML, optionally configured to show a pre-existing value from the form.

The classes that do this are in `Brut::FrontEnd::Components`

| Class | Purpose |
|---|---|
|`Brut::FrontEnd::Components::FormTag` | Creates a `<form>` tag that submits to the form's configured route and includes [CSRF protection](/security). |
|`Brut::FrontEnd::Components::InputTag` | Creates an `<input>` tag |
|`Brut::FrontEnd::Components::RadioButton` | Creates an `<input type="radio">` tag
for use in a radio button group. |
|`Brut::FrontEnd::Components::SelectTagWithOptions` | Creates a `<select>` tag with
`<option>` tags inside. |
|`Brut::FrontEnd::Components::TextareaTag` | Creates a `<textarea>` tag. |
|`Brut::FrontEnd::Components::ButtonTag` | Creates a `<button>` tag to submit the form. |

All of these classes have an initializer that accepts:

* `form:` the form object, used to figure out the HTML attributes and current value of the element.
* `input_name:` to know which input is being generated.
* `index:` for [indexed form elements](/recipes/indexed-forms.md).
* `**html_attributes` any other HTML attributesyou'd like to include.

These class names are quite long, but since these are Phlex components, you can
`include` `Brut::FrontEnd::Components` and access their initializers as a [Phlex
kit](https://phlex.fun):

```ruby
class NewWidgetPage < AppPage
  include Brut::FrontEnd::Components

  def initialize(form: nil)
    @form = form || NewWidgetForm.new
  end

  private attr_reader :form

  def page_template
    FormTag(for: form) do
      Components::InputTag(form:,    input_name: :name)
      Components::InputTag(form:,    input_name: :quantity)
      Components::TextareaTag(form:, input_name: :description)
    end
  end
end
```

Phlex kits provides a methods named for the class that call that class' constructor.

The code above will generate this HTML

```html
<form action="/new_widgets" method="post">
  <input type="hidden" name="authenticity_token" value=«value»>
  <input type="text"   name="name"     required minlength="3">
  <input type="number" name="quantity" required min="0" step="1">
  <textarea name="description">
  </textarea>
</form>
```

Forms accept a single initializer parameter, `params` that is a `Hash`.
`Brut::FrontEnd::Form` implements this initializer, and will pluck values from the
hash to initialize the inputs:

::: code-group

```ruby [Form Class] {5-8}
class NewWidgetPage < AppPage
  include Brut::FrontEnd::Components

  def initialize(form: nil)
    @form = form || NewWidgetForm.new( params: {
      name: "My New Widget",
      quantity: 10,
    })
  end

  # ...

end
```

```html [HTML Generated] {3,5}
<form action="/new_widgets" method="post">
  <input type="hidden" name="authenticity_token" value=«value»>
  <input type="text"   value="My New Widget"
         name="name"     required minlength="3">
  <input type="number" value="10"
         name="quantity" required min="0" step="1">
  <textarea name="description">
  </textarea>
</form>
```

:::

### Accessing Data in a Submitted Form

As mentioned in [routes](/routes), a `form` route implies not just a form class, but
a [handler](/handlers) class to receive the submitted data.

We'll discuss handlers in the next section, but they demonstrate how you can access
a form's data:

```ruby
class NewWidgetHandler < AppHandler
  def initialize(form:)
    @form = form
  end

  def handle
    form.name        # => whatever name was submitted
    form.quantity    # => whatever quantity was submitted
    form.description # => description provided
  end
end
```

A few things to note about how this works:

* Only those inputs declared in the form class can be accessed. All other values are
discarded. No need for "strong parameters".
* All values are strings, because this is what HTML provides.
* Blank values are coerced to `nil`.

The next module will deal with form constraints and validations, in particular how
to manage the user experience around client-side constraint violations, how to
re-check them server side, and how to perform server-side checks.

## Testing

Form classes don't need any logic on them, but they can be given helper methods or other logic if it makes sense. To test them, test them like any other class - instantiate an object and examine the behavior of its methods.

## Recommended Practices

### Create Components to Generate Form Controls

`Brut::FrontEnd::Components::Inputs` will generate the basic tags like `<input>` or
`<select>`.  Everything else like `<label>` is up to you.  We recommend that you
create [components](/components) to generate the markup required for *your* inputs
and controls.

The recipe ["Creating a Text Field"](/recipes/text-field-component) will walk you
through the steps and considerations.

### Take Advantage of Client Side Constraints

Even though client-side constraints can sometimes be awkward in certain browsers,
they are going to be eminently usable and accessible, and you can easily
re-validate them on the server side.

## Technical Notes

> [!IMPORTANT]
> Technical Notes are for deeper understanding and debugging. While we will try to keep them up-to-date with changes to Brut's
> internals, the source code is always more correct.

_Last Updated May 13, 2025_

For HTML generation, there are few classes that work together:

* *input definitions* define an input and tend to provide an API similar to HTML's. See `Brut::FrontEnd::Forms::InputDefinition`.
* *inputs* represent the runtime state of an input from the browser.  Whereas an input definition has no state, the input does. It delegates much of its behavior to the underlying input definition. It's `value=` method performs client-side constraint validations by creating a `Brut::FrontEnd::Forms::ValidityState` internally. See `Brut::FrontEnd::Forms::Input`.
* `Brut::FrontEnd::Forms::InputDeclarations` is a module that allows creating input definitions inside your form
class.  It implements the class methods like `input`.
* `Brut::FrontEnd::Components::Inputs` contains components used to generate `<input>` fields.  These classes will coerce the value of the `input` they are given to generate the correct HTML.
