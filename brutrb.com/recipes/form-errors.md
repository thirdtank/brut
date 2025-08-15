# Styling Form Errors

Brut makes it as easy as possible to unify client-side and server-side constraint violation handling, including
how you style those messages.

## Requirements

What you want:

* When a form is rendered for the first time, there should be errors shown.
* When a visitor interacts with a form before submissions, no errors are shown.
* When the form is submitted, client-side constraint violations should be shown.
* When JavaScript is circumvented and the form is submitted with client-side constraint violations, the form should be re-generated, showing those violations the same is if JavaScripts was *not* circumvented
* When there are no client-side constraint violations, but there *are* server-side violations, the form should be re-generated, showing those violations the same is if JavaScripts was *not* circumvented

This can be achieved through CSS.

## Recipe

### Create Pages and HTML

First, create a form and handler:

```
bin/scaffold form /new_widget
```

Edit `app/src/front_end/forms/new_widget_form.rb`

```ruby
class NewWidgetForm < AppForm
  input :name, minlength: 3
  input :description
end
```

Now, implement the handler in `app/src/front_end/handlers/new_widget_handler.rb` to check for client-side violations *and* require that the description have at
least 5 words in it.

```ruby
class NewWidgetHandler < AppHandler
  def initialize(form:)
    @form = form
  end

  def handle
    if @form.valid?
      if @form.description.split(/\s+/).length < 5
      @form.server_side_constraint_violation(
        input_name: :description,
        key: :not_enough_words
      )
    end

    if @form.constraint_violations?
      NewWidgetPage.new(form: @form)
    else
      redirect_to(HomePage)
    end
  end
end
```

Add the new error message to `app/config/i18n/en/2_app.rb`

```ruby {6}
{
  en: {
    nevermind: "Nevermind",
    cv: {
      ss: {
        not_enough_words: "%{field} must have at least %{minwords} words",
      },
      # ...
```

Now, build a minimal `NewWidgetPage`:

```
bin/scaffold page /new_widget`
```

We'll create the bare minimum in `app/src/front_end/pages/new_widget_page.rb`

```ruby
class NewWidgetPage < AppPage
  def initialize(form: nil)
    @form = form || NewWidgetForm.new
  end

  def page_template
    brut_form do
      FormTag(for: @form) do
        label do
          Inputs::InputTag(form: @form, input_name: :name)
          ConstraintViolations(form: @form, input_name: :name)
          span { "Name" }
        end
        label do
          Inputs::TextareaTag(form: @form, input_name: :name)
          ConstraintViolations(form: @form, input_name: :name)
          span { "Description" }
        end
      end
    end
  end
end
```

### Create CSS

The most minimal CSS would be as followed, which you can place in `app/src/front_end/css/index.css`

```css
brut-cv {
  display: none;
}

brut-form[submitted-invalid] brut-cv,
brut-cv[server-generated] {
  display: block;
  color: red;
}
```

This will show the messages in `<brut-cv>` *only* if:

* Form submission was attempted (`submitted-invalid` would be set on `<brut-form>`)
* The server generated via `ConstraintViolations` (only if the handler was triggered)

Because more than one `<brut-cv>` could be generated or inserted, you may want to style the
`<brut-cv-messages>` that contains them, but you only want it to show up if it has contents.

You can't just do `brut-cv-messages:has(brut-cv)`, because your container would show up before the form
submission was attempted.

Here is what you want instead. This will put the error messages in a red box:

```css
brut-form[submitted-invalid] brut-cv-messages:has(brut-cv),
brut-cv-messages:has(brut-cv[server-generated]) {
  color: red;
  background-color: pink;
  border: solid thin red;
  border-radius: 1rem;
}
```

