# Form Validation

Processing a form submission usually requires validating the data.   The web
APIs refer to validations as *constraints*. Brut supports both client and
server-side constraints, as well as the ability to validate client-side
constraints on the server.

## Setting Client-Side Constraints

The form class is where you set client-side constraints. These are the
constraints supported by the web platform.  No other constraints can be modeled
this way on the form.  The form class' entire purpose is to generate HTML for a
form and hold the form data that was submitted.

Here is the form class created in [Create a Form and Handle its
Submission](./form-basic):

```ruby
class UserPreferencesForm < AppForm
  input :account_name,      type: :text, required: false
  input :default_num_tasks, type: :number
  input :default_public,    type: :checkbox
end
```

This means that:

* `account_name` can be anything, and is not required
* `default_num_tasks` is required, and must be a number
* `default_public` will be true or false

Let's require that `default_num_tasks` be positive.  In HTML, this is achieved
by setting the `min` attribute on `<input type="number">`.  In a Brut form
class, we set the `min:` keyword argument to `input`, like so:

```ruby {3}
class UserPreferencesForm < AppForm
  input :account_name,      type: :text, required: false
  input :default_num_tasks, type: :number, min: 1
  input :default_public,    type: :checkbox
end
```

We don't have to change HTML generation that uses `UserPreferencesForm`.  With
this change we just made, the `<input>` will now look like so:

```html
<input type="number" name="default_num_tasks" min="1">
```

Because we surrounded our `<form>` with a `<brut-form>` and because we used
`Brut::FrontEnd::Components::ConstraintViolations`, if `default_num_tasks` is
omitted, not a number, or not positive, the form will not be submitted to the
server and an error message will be inserted into the form.

## Re-Checking Client-Side Constraints on the Server

There's no gurantee that a form submission passed all the client-side
constraints.  But, because we've modeled those constraints on the server in our
form class, we can re-validate them.

The structure of your handler should be:

1. Re-check client-side constraints
2. If those pass, check any server-side constraints
3. If the form is left without any constraint violations, execute your logic
4. Otherwise, re-render the original page with the values provided, along with constraint violation messages

Here's how it would look to just re-check the client-side constraints.

```ruby {7,15}
class UserPreferencesHandler < AppHandler
  class initialize(form:)
    @form = form
  end

  def handle
    if @form.valid?
      DB::UserPreferences.create(
        account_name: @form.account_name,
        default_num_tasks: @form.default_num_tasks,
        default_public: @form.default_public
      )
      redirect_to(PreferencesPage)
    else
      PreferencesPage.new(form: @form)
    end
  end
end
```

`.valid?` will implicitly re-check the client-side constraints and, if any have
been violated, return false.  Note that returning an instance of a page allows
you to control its initialization. In this case, we pass in our form instance,
which contains the constraint violations.  `Inputs::ConstraintViolations`
will use that to generate error messages for the website visitor.

## Server-Side Constraints

Let's suppose that `account_name` may not be a reserved name like "default", "main", or "acme". While we might be able to craft a regular expression for this, let's do this check server-side since it will be easier to build and understand.

There is currently no framework for modeling server-side constraints, so you
will have to use plain source code.  When you find a constraint violation, you
will call `server_side_constraint_violation` on the form instance.  You'll give
it a key that maps to the error message.

Here's the change to the handler:

```ruby {8-13,15}
class UserPreferencesHandler < AppHandler
  class initialize(form:)
    @form = form
  end

  def handle
    if @form.valid?
      if RESERVED_NAMES.include?(@form.account_name.to_s.downcase)
        @form.server_side_constraint_violation(
          input_name: :account_name,
          key: :account_name_reserved
        )
      end
    end
    if @form.valid?
      DB::UserPreferences.create(
        account_name: @form.account_name,
        default_num_tasks: @form.default_num_tasks,
        default_public: @form.default_public
      )
      redirect_to(PreferencesPage)
    else
      PreferencesPage.new(form: @form)
    end
  end
  RESERVED_NAMES = [ "default", "main", "acme" ]
end
```

Note that calling `server_side_constraint_violation` will cause subsequent
calls to `.valid?` to return false.  This logic means that we only check
server-side constraints if client-side constraints are all satisfied.

You will need to add `account_name_reserved` to `app/config/i18n/en/2_app.rb`:

```ruby {8}
# app/config/i18n/en/2_app.rb
{
  en: {
    cv: {
      cs: {
      },
      ss: {
        account_name_reserved: "This account name is reserved for internal use",
      },
    },
    # ...
  },
}
```

"cv" is for *constraint violations* and "ss" is for *server side*.

Now, when you submit the form using the name "default", you should see this
message rendered in the HTML.
