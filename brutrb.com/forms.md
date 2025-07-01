# Forms

The most common way for a web site visitor to submit data to the server is to submit a form.  The Web Platform's forms API is much like an uncle you may have: old and rich.

Brut's forms module solves three problems:

* Descrbing the data being collected and submitted
* Providing access to the submitted form data on the server
* Support for creating a good client-side experience regarding constraint violations, both client-side and
server-side.

## Overview

The forms module has a lot of moving parts, but the general process of using forms is:

1. Create a *form class* to describe the data in your form.
2. Use an instance of that form class to generate HTML for the elements of the form.
3. Implement a *handler class* that will receive an instance of your form class, populated with the data provided when the form was submitted. (**Note**: forms generally cannot contain data submitted by the browser that was not described by the form class, thus obviating the need for something like Rails' strong parameters).
4. Add server-side constraint violations to the form and re-render your HTML or use the form data as input to a
   back-end process.

### Forms Are Submitted to Routes

When you have a form to process, create a `form` route (remember, all routes must follow the [rules of routing](/routes)):

```ruby{6}
class App < Brut::Framework::App

  # ...

  routes do
    form "/login"

    # ...
  end
end
```

Because a form is not a url, the `form` method will set up two expectations of your code:

* There should be a form class, in this example named `LoginForm`
* There should be a handler class, in this example named `LoginHandler`.

When a browser issues an HTTP `POST` to `/login`, the forms contents will populate an instance of
`LoginForm`, which will be given to an instance of a `LoginHandler` to process the form submission.

First, let's go through the bare minimum of form processing.

### Simplest Case of Form Processing

#### Creating a Form Class

All form classes must be subclasses of `Brut::FrontEnd::Form`, though practically speaking, yours will subclass `AppForm`, which subclasses `Brut::FrontEnd::Form`.  The form class allows you to use various class methods to declare your form's inputs.

Let's take a simple example of a login form that has an email and a password.  We'll use `input` to declare two
`<input>` elements.  `input`, like `<input>` accepts a type. Brut recognizes the same list of types as modern
browers.  In this case, we want `type="email"` and a `type="password"` inputs:

```ruby
# app/src/front_end/forms/login_form.rb
class LoginForm < AppForm
  input :email, type: :email
  input :password, type: :password
end
```

#### Generating HTML with a Form Object

Let's suppose we have a `LoginPage` that will include this form.  Below is a sketch of the implementation. Note
that `form_tag` is a Brut-provided method that will create an HTML `<form>` but also include a hidden field used
for CSRF protection.

```ruby
# app/src/front_end/pages/login_page.rb
class LoginPage < AppPage
  def initialize
    @form = LoginForm.new
  end

  def page_template
    form_tag(method: :post,
             action: LoginHandler.routing) do
      # ...
      button { "Login" }
    end
  end
end
```

Brut can generate the HTML for the needed inputs via `Brut::FrontEnd::Components::Inputs::TextField`, which is a very long class name.  Hold that thought for now. This method will generate an `<input>` element for you, based on how you've set up the field in your form class. The HTML element will have a value set based on the form, if there is a value.

```ruby {11,12}
# app/src/front_end/pages/login_page.rb
class LoginPage < AppPage
  def initialize
    @form = LoginForm.new
  end

  def page_template
    form_tag(method: :post,
             action: LoginHandler.routing) do
      # We promise you don't have to type this every time!
      Brut::FrontEnd::Components::Inputs::TextField.new(form: @form, input_name: :email)
      Brut::FrontEnd::Components::Inputs::TextField.new(form: @form, input_name: :password)
      button { "Login" }
    end
  end
end
```

This produces the following HTML (formatted here for clarity):

```html
<form method="post" action="/login">
  <input type="email"    name="email"    required>
  <input type="password" name="password" required>
  <button>Login</button>
</form>
```

Note that each fields type and name match what was used in `LoginForm`.  Also note that both fields have the `required` attribute. We'll discuss why in a moment.

#### Expedient Access to Brut Components

`Brut::FrontEnd::Components` is the root namespace of, among other things, [components](/components) provided by Brut.  Components are Phlex components that generate HTML and can be accessed as a Phlex *kit*, by including the namespace in your class:


```ruby {2}
# app/src/front_end/pages/login_page.rb
class LoginPage < AppPage
  include Brut::FrontEnd::Components

  # ...
end
```

This allows you to call `Inputs::TextField` like a method:

```ruby {12,13}
# app/src/front_end/pages/login_page.rb
class LoginPage < AppPage
  include Brut::FrontEnd::Components

  def initialize
    @form = LoginForm.new
  end

  def page_template
    form_tag(method: :post,
             action: LoginHandler.routing) do
      Inputs::TextField(form: @form, input_name: :email)
      Inputs::TextField(form: @form, input_name: :password)
      button { "Login" }
    end
  end
end
```

Brut prefers this style, instead of a bag of random helpers, to make it more clear where the logic being
called is actually coming from. In practice, you would create your own re-usable components for input
fields that use `Brut::FrontEnd::Components::Inputs::TextField` and friends, so even if you find the kit
version too long, it's not something you should be typing a lot.

#### Receive the Submission

When the website visitor clicks the "Login" button, the form's data is submitted to `/login` via an HTTP Post.
Brut expects the class `LoginHandler` to exist and will call its `handle!` method. A *handler* must extend
`Brut::FrontEnd::Handler`, though practically speaking it will extend your app's `AppHandler`, which extends `Brut::FrontEnd::Handler`.

The handler's initializer's signature indicates what data should be passed-in by Brut.  Since this is processing a
form submission, the `form:` parameter should be included.  If it is, an instance of `LoginForm`, populated with the data provided by the website visitor, will be passed to the initializer. It can accept other parameters as well, but we'll discuss that later.

Note that *you* must implement `handle`, which `handle!` calls:

```ruby
# app/src/front_end/handlers/login_handler.rb
class LoginHandler < AppHandler
  def initializer(form:)
    @form = form
  end
  def handle
    # ...
  end
end
```

Typically, `handle` will implement a common pattern: checking the validity of the form submission and, if it's
not valid, re-render the previous page with errors, whereas if it is valid, execute some back-end logic.

If you'll remember, both email and password were set as required in the HTML.  We'll talk about how to control
that behavior later, but it does mean that the browser would not submit form data without those values provided.
That said, JavaScript could be circumvented, so our handler could be called without either of those fields.

Because `LoginForm` describes the inputs *and* we used an instance of it to generate HTML, that instance can  re-evaulate the client-side constraints at any time. The handler does this by calling `#constraint_violations?`.

```ruby {7}
# app/src/front_end/handlers/login_handler.rb
class LoginHandler < AppHandler
  def initialize(form:)
    @form = form
  end
  def handle
    if @form.constraint_violations?
      # ...
    else
      # ...
    end
  end
end
```

Of course, some constraints can't be validated
client-side and require some back-end logic.  In this case, we want to check that there is an authorized user
with that email and password. Let's assume the existence of the class `AuthorizedUser` that has a class method
`login` that returns `nil` if there is no user with that email/password combination.

If that returns `nil`, we want to re-render the `LoginPage`, exposing some sort of constraint violation message
so it can be rendered. We also want the form fields to be pre-filled with the values the visitor provided.

`Brut::FrontEnd::Components` can handle this, so we need to pass our form object into `LoginPage` instead of allowing `LoginPage` to create an empty one.  We can do that by adding a `form:` keyword argument that defaults to `nil`:

```ruby {3,4}
# app/src/front_end/pages/login_page.rb
class LoginPage < AppPage
  def initialize(form: nil)
    @form = form || LoginForm.new
  end

  def page_template
    form_tag(method: :post,
             action: LoginHandler.routing) do
      Inputs::TextField(form: @form, input_name: :email)
      Inputs::TextField(form: @form, input_name: :password)
      button { "Login" }
    end
  end
end
```

To trigger this behavior, the handler will:

* Call `server_side_constraint_violation` on the form instance.
* Pass it to `LoginPage.new`, which it will return, thus re-rendering the page (when a handler's `handle!` method returns an instance of a page, that page's HTML is generated as the response).

```ruby {10-13,17}
# app/src/front_end/handlers/login_handler.rb
class LoginHandler < AppHandler
  def handle(form:)
    if !form.constraint_violations?
      authorized_user = AuthorizedUser.login(
        email: form.email,
        password: form.password
      )
      if authorized_user.nil?
        form.server_side_constraint_violation(
          input_name: :email,
          key: :login_not_found
        )
      end
    end
    if form.constraint_violations?
      LoginPage.new(form: @form)
    else
      # ...
    end
  end
end
```

When `LoginPage` generates HTML, different HTML is generated, since the form being passed to the components contains constraint violations.

#### Showing Constraint Violations in HTML

When `Brut::FrontEnd::Components::Inputs::TextField` is created with an existing form that has constraint violations, different HTML is generated.  This is what would be produced by our existing `LoginPage` (again, formatted her for clarity):

```html {3}
<form method="post" action="/login">
  <input type="email"  name="email"    required
         data-invalid  data-login_not_found>
  <input type="password" name="password" required>
  <button>Login</button>
</form>
```

These `data-` attributes allow you to target these fields with CSS.

Actual error messages aren't shown since we didn't put in any HTML that might hold them.  The form object
is capable of exposing the constraint violations as keys, intended to be used by the [I18n system](/i18n).

In general, you don't want to do this directy, but the API looks like so:

```ruby
form.input(:email).validity_state.each do |constraint|
  # use constraint.key to construct a message
end
```

The reason to avoid this is that a) Brut provides a built-in component to generate HTML and b) if you use
Brut's component, you can achieve parity between client-side constraint violations detected by the browser
and server-side violations identified by your app.

### Forms and Constraint Violations

There are two common issues around constraint violations in HTML forms:

* Handling the case where JavaScript is circumvented and invalid data is submitted to the server.
* Unifying how client- and server-side constraint violations are shown the user.

We saw that the use of form classes handles the first issue: a form created with submitted data can self-validate its configured client-side constraints.  In this section, we'll see how to unify the violations from both client- and server-side, which will include actually showing error messages.

Above, we mentioned that each constrait violation is represented by a key to be used with the [I18n
system](/i18n).  For client-side violations, these keys are limited to those that are part of the web platform's [`ValidityState`](https://developer.mozilla.org/en-US/docs/Web/API/ValidityState) class.  For example, `patternMismatch` is the key used when an input field's value doesn't match the regular expression set in the `pattern` attribute.

Brut provides default translations for these in `app/config/i18n/en/1_defaults.rb` under the prefix
`cv.fe` (`cv` being short of "constraint violation" and `fe` being short for "front end"). Note that these
keys match `ValidityState` so are in camel-case, not Ruby's idiomatic snake-case.

Back-end constraint violations are expected to have keys under `cv.be` (`be` for "back-end"), and these
keys *should* conform to Ruby's idioms.

Let's look at showing server-side constraints first, since those are more like what you may be familiar
with coming from Rails.

#### Showing Server-Side Violations

Brut provides the component `Brut::FrontEnd::Components::ConstraintViolations`, which will render all the markup you need for both server- and client-side violations.  When there are server-side violations, this component will handle generating the actual error messages.

Because we've included `Brut::FrontEnd::Components`, the Phlex kit allows
`ConstraintViolations` to be called directly, like so:

```ruby {7,10}
# Inside app/src/front_end/pages/login_page.rb
def page_template
  form_tag(method: :post,
           action: LoginHandler.routing) do

    Inputs::TextField(form: @form, input_name: :email)
    ConstraintViolations(form: @form, input_name: :email)

    Inputs::TextField(form: @form, input_name: :password)
    ConstraintViolations(form: @form, input_name: :password)

    button { "Login" }
  end
end
```

In the case where we've set the server-side constraint violation for the email field, and assuming that the i18n
key "cv.be.login\_not\_found" maps to the string "No login with that email/password", here is the HTML that
will be rendered:

```html {4-8,11-12}
<form method="post" action="/login">
  <input type="email"  name="email"    required
         data-invalid  data-login_not_found>
  <brut-cv-messages input-name="email">
    <brut-cv server-side>
      No login with that email/password.
    </brut-cv>
  </brut-cv-messages>

  <input type="password" name="password" required>
  <brut-cv-messages input-name="password">
  </brut-cv-messages>

  <button>Login</button>
</form>
```

`brut-cv-messages` and `brut-cv` are [autonomous custom
elements](https://developer.mozilla.org/en-US/docs/Web/API/Web_components/Using_custom_elements).  If you aren't
familiar with this part of the web platform, there are two things to know:

* These elements can be targeted with CSS without any JavaScript executing at all (they are treated and rendered by the browser as if they are `display: inline` elements).
* It's possible to attach behavior to these with JavaScript to add progressively-enhanced behavior.

Without any JavaScript, you now have the basis for styling your error messages *and* the server-side messages are
now rendered using internationalization.  As a very basic demonstration, you could place this in
`app/src/front_end/css/index.css`:

```css
input[data-invalid] { 
  color: red;
  background-color: mistyrose; /* yes, that's a CSS color :) */
}
brut-cv-messages {
  color: red;
  display: block;

  brut-cv {
    display: block;
  }
}
```

#### Dynamically Showing Client-Side Violations

It would be nice if, when the browser detects client-side violations before the user submits the form, the
same UI could be used to show *those* error messages.  Brut achieves this via the aforementioned
autonomous custom elements.

You'll note that even though the password field had no constraint violations, `<brut-cv-messages input-name="password">` was still generated for it. This element, working in conjuction with a few other elements, will provide localized messaging for client-side constraint violations using the same markup and CSS as your server-side constraint violations.

* `<brut-form>` will manage the `<form>` it contains to listen for any violations
* `<brut-cv-messages>` identifies where error messages should go, per form element.
* `<brut-cv>` contains a specific message or key.
* `<brut-i18n-translation>` maps keys from `<brut-cv>` elements to actual translated strings.

Together, these elements will show the visitor localized error messages exactly the same way as
server-side error messages are shown.

First, we need to wrap our form with `brut-form`:

```ruby {3,15}
# Inside app/src/front_end/pages/login_page.rb
def page_template
  brut_form do
    form_tag(method: :post,
             action: LoginHandler.routing) do

      Inputs::TextField(form: @form, input_name: :email)
      ConstraintViolations(form: @form, input_name: :email)

      Inputs::TextField(form: @form, input_name: :password)
      ConstraintViolations(form: @form, input_name: :password)

      button { "Login" }
    end
  end
end
```

Second, we need `<brut-i18-translation>` elements on the page somewhere.  These *should* be in your
default layout and look like so:

```ruby {7,8}
# app/src/front_end/layouts/default_layout.rb
def view_template
  doctype
  html(lang: "en") do
    head do
      # ...
      I18nTranslations("cv.fe")
      I18nTranslations("cv.this_field")
      # ...
    end
    body do
      yield
    end
  end
end
```

`I18nTranslations` is a shortcut to `Brut::FrontEnd::Components::I18nTranslations`, which is a component to
render one `<brut-i18n-translation>` element per transalation found under the given prefix.  Thus, it
would generate HTML like so:

```html
<brut-i18n-translation
  key="cv.fe.badInput"
  value="%{field} is the wrong type of data">
</brut-i18n-translation>
<brut-i18n-translation
  key="cv.fe.patternMismatch"
  value="%{field} isn't in the right format">
</brut-i18n-translation>
<!-- etc. -->
```

With this in place, here is how this works:

1. The `<brut-form>` listens for constraint violations on the `<form>` elements.
2. When one is detected, it then locates the `<brut-cv-messages>` element for that element's name (based on the `input-name` attribute).
3. `<brut-form>` will insert one `<brut-cv>` for each constraint that element's value violates, based on `ValidityState`. The value from `ValidityState` is used to create an I18n key, for example `<brut-cv key="cv.fe.patternMismatch"></brut-cv>`.
4. `brut-cv` itself is a custom element that will use its `key` attribute to locate the actual message to show.  That message is expected to be in a `<brut-i18n-translation>` element with a matching key, somewhere on the page.

This may seem convoluted, however it separates concerns reasonably well and allows localization of the messaging.

If your visitor's locale is not `en`, the layout would render different values for each `<brut-i18n-transation>` elements, thus allowing client-side constraint violations to be shown in the visitor's language.

You can now style these client-side messages with a slight change to your CSS:

```css {2}
input[data-invalid],
input:invalid { 
  color: red;
  background-color: mistyrose;
}
brut-cv-messages {
  color: red;
  display: block;

  brut-cv {
    display: block;
  }
}
```

Note that a) this didn't require a lot of code on your part, b) the server is still re-evaluating the
client-side constraints, so the visitor will see them, even if JavaScript is off or fails, and c) it
sticks as closely to the web platform as possible.

That all said, this implementation falls vicitim to an annoyance of client-side constraint violations, which is prematurely showing error messages.

#### Managing Errors Shown Before Submission

I'm sure we've all experienced over-zealous forms where typing a single character into an email field reveals a blaring red message that our email is not valid.  Brut's custom elements can help.

You can certainly use [`user-invalid`](https://developer.mozilla.org/en-US/docs/Web/CSS/:user-invalid) to help address this problem, but it doesn't always work how you'd think, and is only recently available in
[Baseline](https://developer.mozilla.org/en-US/docs/Glossary/Baseline/Compatibility).

To help, `brut-form` will set the attribute `submitted-invalid` on itself if the user has attempted to submit the form with data that violates the client-side constraints. A slight change to CSS will cause your error messages to only show up when submission has been attempted:

```css 
/* First, hide client-side messaging by default.
   Server-side messages will always appear */
form {
  brut-cv {
    display:none;
  }
  brut-cv[server-side] {
    display:block;
  }
}

/* Now, show constraint violations only if 
   submitted-invalid was set */
brut-form[submitted-invalid] {
  brut-cv {
    display:block;
  }
}

/* Always show elements with data-invalid since that 
   is server-generated, but only style the elements
   as invalid if the form has submitted-invalid on it */
input[data-invalid],
brut-form[submitted-invalid] input:invalid { 
  color: red;
  background-color: mistyrose;
}

brut-cv-messages {
  color: red;
  display: block;
}
```

Now, client-side constraint violations will only be shown to the user when they attempt to submit the form.  Note that you have complete control, since this is all impelmented using standard CSS.  Brut and its custom elements give you the tools and hooks to style as you see fit.

### Checkboxes

Checkboxes are implemented in HTML by `<input type="checkbox">`, so in your form, you would use `type:
:checkbox`:

```ruby {5,6}
# app/src/front_end/forms/login_form.rb
class LoginForm < AppForm
  input :email,     type: :email
  input :password,  type: :password
  input :remember,  type: :checkbox
  input :not_robot, type: :checkbox
end
```

Checkboxes can be rendered by a `Brut::FrontEnd::Components::Inputs::TextField`, and their `value` attribute would always be the string `"true"`. If the form's value for the input is the string `"true"`, the checkbox would have the `checked` attribute:

```html
<!-- Form.new(params: { remember: "true" }) -->
<input type="checkbox" name="remember"  value="true" checked>
<input type="checkbox" name="not_robot" value="true">
```

### Radio Buttons

Radio buttons are implemented in HTML by `<input type="radio">`, with an expectation of more than one such input
having the same value for the `name` attribute, but different values for the `value` attributes, one of which may
be `checked`.

Brut implements this via `Brut::FrontEnd::Components::Inputs::RadioButton`, whose initializer behaves like the other form input components. To create radio buttons in a form, use `radio_button_group`:

```ruby {5}
# app/src/front_end/forms/login_form.rb
class LoginForm < AppForm
  input :email,    type: :email
  input :password, type: :password
  radio_button_group :remember
end
```

The form would not need to be configured with the possible values - that will happen when you generate HTML:

```ruby
def view_template
  form do
    [ :never, :one_week, :one_month ].each do |remember|
      label do
        render(
          Inputs::RadioButton(
            form:,
            input_name: :remember,
            value: remember
          )
        )
        plain { remember.to_s }
      end
    end
  end
end
```

When generating HTML, Brut will examine the value of `form.remember` to know which radio button to check.  To set
a default, set that value when creating the form:

```ruby {4-6}
# app/src/front_end/pages/login_page.rb
class LoginPage < AppPage
  def initialize(form: nil)
    @form = form || LoginForm.new(params: {
                      remember: "never"
                    })
  end
```

### Selects

Selects are implemented in HTML by a `<select>` that has a `name` attribute, and contains several `<option>` elements, each having a `value` attribute.  They work like radio buttons in Brut, in that you would not specify the possible values in the form class.

> [!WARNING]
> Brut does not support multi-selects, yet.


You can set up a select via `select`

```ruby {5}
# app/src/front_end/forms/login_form.rb
class LoginForm < AppForm
  input :email,    type: :email
  input :password, type: :password
  select :remember
end
```

Creating the HTML can be done with `Brut::FrontEnd::Components::Inputs::Select`. It's initializer is more complex, since it provides a way to show visitor-friendly values instead of the innate `value` for each option, as well as to allow for a "blank" entry.

Let's suppose we have a class named `LoginRememberOption`. It's a simple wrapper around a value we might store in the database and use to lookup an I18n key.

```ruby
class LoginRememberOption
  include Brut::I18n::ForBackend
  def initialize(value)
    @value = value
  end

  def to_s = @value

  def name
    t("login.remember_options.#{@value}")
  end

  def self.all
    [
      LoginRememberOption.new("never"),
      LoginRememberOption.new("one_week"),
      LoginRememberOption.new("one_month"),
    ]
  end
end
```

To show these options in a `<select>`, we might do this:

```ruby
def view_template
  form do
    render(
      Inputs::Select(
        form:,
        input_name: :remember,
        options: LoginRememberOption.all,
        value_attribute: :to_s,
        option_text_attribute: :name,
        include_blank: {
          value: :blank,
          text_content: "-- Choose --",
        }
      )
    )
  end
end
```

This will create this HTML (making some assumptions about the translations):

```html
<select name="remember">
  <option value="blank">-- Choose --</option>
  <option value="never">Never</option>
  <option value="one_week">One Week</option>
  <option value="one_month">One Month</option>
</select>
```

### Arrays of Values

Some complex forms involve a potentially arbitrary number of inputs for a given field.  For example, you might allow the visitor to edit widgets in bulk, 10 at a time.

Brut can handle this, with help from Rack.  First, you'll use `array: true` when declaring an input:

```ruby
class BulkWidgetForm < AppForm
  input :name, array: true, required: false
end
```

In this case, we need `required: false` or every single field we generate will be required.

To generate the HTML, use the optional `index:` parameter to the initializer as well as for `ConstraintViolations`:

```ruby {11,16}
# Inside e.g. app/src/front_end/pages/create_bulk_widget_page.rb
def page_template
  brut_form do
    form_tag(method: :post,
             action: BulkWidgetForm.routing) do

      10.times do |i|
        Inputs::TextField(
          form: @form,
          input_name: :name,
          index: i
        )
        ConstraintViolations(
          form: @form,
          input_name: :email,
          index: i
        )
      end

      button { "Save" }
    end
  end
end
```

This will generate HTML like so:

```html
<!-- ... -->
<input name="name[]">
<!-- ... -->
<input name="name[]">
<!-- ... -->
```

The `[]` is a Rack-specific format that will provide the values to the server as an array. While this is not supported nor required of the web platform, Rack does not provide all values for a given input name, unless that name has the `[]` suffix.

Also note that you do not have to specify a max length of the array. You can use as many as you like, just be sure that the index values are monotonically increasing with no gaps.

In the handler, values can be accessed by index:

```ruby {4}
# app/src/front_end/handlers/bulk_widget_handler.rb
class BulkWidgetHandler < AppHandler
  def handle
    @form.name(2) # name with index 2 i.e. the 3rd value
  end
end
```

To set the values, you must provide an array to `params:`:

```ruby {3}
widgets = DB::Widget.order(:created_at).limit(10)
BulkWidgetForm.new(params: {
  name: widgets.to_a.map(&:name),
})

# OR
BulkWidgetForm.new(params: {
  name: [
    "",
    "",
    "Third Widget",
    "",
    ""
  ],
})
```

To set server-side constraint violations, `index:` can be used:

```ruby {4}
form.server_side_constraint_violation(
  input_name: :name,
  key: :must_be_two_words,
  index: 3
)
```

This can be quite complicated when editing sparse data.  Brut should do a decent job raising an error if you try to treat a non-array value as an array or vice-versa.

## Testing

Form classes don't need any logic on them, but they can be given helper methods or other logic if it makes sense.
To test them, test them like any other class - instantiate an object and examine the behavior of its methods.

Note that Brut provides the constructor for all form classes, and it expects a single keyword parameter named `params:`
that is a hash mapping strings to strings representing the submitted form data. The keys can be symbols and Brut will
map them to strings.

Testing handlers is covered in [Handlers](/handlers)

When testing the UX around constraint violations, you should use an end-to-end test, as this will allow you to
assert behavior around client-side constraint violations.  This is discussed in [End-to-end
Tests](/end-to-end-tests).

## Recommended Practices

### Make Use of Components

The example we saw above creates only minimal markup, yet required a fair bit of code.  You are encouraged to
create your own components that generate the markup you need for your app's inputs.  For example, you are likely
going to want `app/src/front_end/components/text_field_component.rb` to generate whatever markup is needed fo
your text fields to look how they are supposed to, with and without constraint violation messages.

### Functional or Utility CSS Is Difficult Here

The way constraint violations are implemented leverages the web platform, which naturally includes conventional use of CSS.  This creates an "impedance mismatch" with functional or utility CSS like Tailwind.

While it may be possible to write a bunch of single-purpose classes to target the markup and attributes Brut generates, it may be easier to write conventional CSS for constraint violations.

To avoid duplication, you should leverage the custom properties of your CSS framework. For example:

```css
input[data-invalid] {
  color: var(--color-red);
}
```

In theory, your design for form inputs will be done once and be relatively stable.  But, this is the downside of using CSS frameworks that eschew using CSS directly.  You will need to manage this.

## Technical Notes

> [!IMPORTANT]
> Technical Notes are for deeper understanding and debugging. While we will try to keep them up-to-date with changes to Brut's
> internals, the source code is always more correct.

_Last Updated May 13, 2025_

Form internals try to coerce types to strings, since the web and HTTP is all strings all the time.  Empty strings
are coerced to `nil`.  If the form's `params:` value contains any type Brut cannot deal with, you'll get an
exception during tests and a notice/event in production.

For HTML generation, there are few classes that work together:

* *input definitions* define an input and tend to provide an API similar to HTML's. See `Brut::FrontEnd::Forms::InputDefinition`.
* *inputs* represent the runtime state of an input from the browser.  Whereas an input definition has no state, the input does. It delegates much of its behavior to the underlying input definition. It's `value=` method performs client-side constraint validations by creating a `ValidityState` internally. See `Brut::FrontEnd::Forms::Input`.
* `Brut::FrontEnd::Forms::InputDeclarations` is a module that allows creating input definitions inside your form
class.  It implements the class methods like `input`.
* `Brut::FrontEnd::Components::Inputs` contains components used to generate `<input>` fields.  These classes will
coerce the value of the `input` they are given to generate the correct HTML.
