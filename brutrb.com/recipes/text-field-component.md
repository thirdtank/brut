# Creating your Own Text Field Component

Brut's `Brut::FrontEnd::Components::Input::InputTag` creates only the `<input>` HTML
element.  You will likely want something more sophsticated. You can achieve this by
creating your own component.

## Feature

We'll make a text field that has a label, error messages, and styling.  It will
support three sizes: small, normal, and large.

It will require a form and an input name, and optional index as well.

## Recipe

### Create the Initializer

First, we'll create the component:

```
bin/scaffold component text_field
```

Now, edit the initializer to accept the parameters we need:

```ruby
# app/src/front_end/components/text_field_component.rb
class TextFieldComponent < AppComponent
  def initialize(form:,
                 input_name:,
                 index: 0, # default for non-array values
                 size: :normal)
    @form       = form
    @input_name = input_name
    @index      = index
    @size       = size
  end
end
```

### Outline the HTML

We'll want HTML like so:

```html
<label>
  <input ...>
  <span>LABEL HERE</span>
  <brut-cv-messages></brut-cv-messages>
</label>
```

Before we worry about CSS or styling, let's sketch this out in `view_template`.  The
actual label text will come from our I18n setup. We'll assume a "labels" top-level
section that has sections for each form and then inside that, each input name:

```ruby
# app/config/i18n/en/2_app.rb
{
  "labels": {
    "LoginForm": {
      "email": "Email addressed you used when singing up",
      "password": "Your password",
    }
  }
}
```

```ruby
# app/src/front_end/components/text_field_component.rb
class TextFieldComponent < AppComponent

  include Brut::FrontEnd::Components

  private attr_reader :form, :input_name, :index
  def view_template
    label do
      InputTag(form:, input_name:, index: )
      span { raw(t([ "labels", form.class.name, input_name ])) }
      ConstraintViolations(form:, input_name:, index:)
    end
  end
end
```

### Styling the Component

Styling can happen in a few ways.  For simplicity, we'll use CSS and have minimal
classes on our HTML.  Since the structure is all inside a `<label>`, we'll add a
class on that, named for our component. We'll also include form and input names
in the class to allow overriding if needed.  Lastly, we'll include the
size as well.

```ruby {8-14}
# app/src/front_end/components/text_field_component.rb
class TextFieldComponent < AppComponent

  include Brut::FrontEnd::Components

  private attr_reader :form, :input_name, :index
  def view_template
    label_classes = [
      class.name,
      class.name + "-#{@size}",
      form.class.name,
      input_name
    ]
    label(class: label_classes) do
      InputTag(form:, input_name:, index: )
      span { raw(t([ "labels", form.class.name, input_name ])) }
      ConstraintViolations(form:, input_name:, index:)
    end
  end
end
```

Let's create `app/src/front_end/css/TextFieldComponent.css`, which we'll need to
`@import`:

```css
/* app/src/front_end/css/index.css */
@import "TextFieldComponent.css";
```

The CSS will assume BrutCSS's design system is available:

```css
/* app/src/front_end/css/TextFieldComponent.css */
.TextFieldComponent {
  label {
    display: flex;
    flex-direction: column;
    gap: var(--sp-2);
  }
  input {
    border: solid thin var(--gray-500);
    border-radius: var(--br-3);
    padding: var(--sp-2);
    font-size: var(--fs-3);
  }
  span {
    font-size: var(--fs-2);
    font-stye: italic;
    color: var(--gray-400);
  }
  /** We assume the general styling for brut-form
      and brut-cv exists in index.css */
  brut-cv {
    color: red;
  }
  &.TextFieldComponent-small {
    input {
      font-size: var(--fs-1);
    }
  }
  &.TextFieldComponent-large {
    input {
      font-size: var(--fs-4);
    }
  }
}
```

### Using the Component

To use this component, we can create an instance and send it to Phlex's `render`:


```ruby
def view_template
  brut_form do
    FormTag(for: @form) do
      render TextFieldComponent.new(form: @form,
                                    input_name: :name)
      render TextFieldComponent.new(form: @form,
                                    input_name: :quantity,
                                    size: :small)
      button { "Save" }
    end
  end
end
```
