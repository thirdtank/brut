# Create a Form and Handle its Submission

Form handling in Brut involves three things:

* A form class that defines the fields on the form
* A route where the form's fields are submitted
* A handler class that will be used to handle the submission to that route

`brut scaffold form` can set up a lot of the infrastructure.

## Create the Route, Form, and Handler

Decide on the name of your form/handler, which will be used to name the route.
Remember, Brut doesn't care about resources, so name the form whatever the
non-programmers on your team would call it.  In this example, we'l call it the
*user preferences* form.

The route would be `/user-preferences` so we can use that to run `brut scaffold
form`

```bash
dx/exec brut scaffold form /user-preferences
```

This will create a form class, a handler class, a test for both, and an entry
in `app.rb` for the new route.

## Define the Form's Fields

In Brut, you define form fields on the form class. They can have the same types
and constraints as an HTML form.  For this example, we'll define three fields:
An optional account name, a default number of tasks for new projects, and a
a checkbox for new projects to be public or not.

The file to edit is in `app/src/front_end/forms/user_preferences_form.rb` and
should look like so after adding the fields:

```ruby
class UserPreferencesForm < AppForm
  input :account_name,      type: :text, required: false
  input :default_num_tasks, type: :number
  input :default_public,    type: :checkbox
end
```

Note that fields other than checkboxes are required by default, thus why `required: false` is set for `:account_name`.

With these fields defined, the HTML can be generated.

## Generate HTML

We'll assume a page called *preferences page* where the form will live.  This
page would be in `app/src/front_end/pages/preferences_page.rb`.

The form's HTML needs to:

* Submit to the form's route (`/user-preferences`)
* Use the names and types from our form class
* Render any default values we've provided

To do this, we'll use the form itself as a data source.  The best practice is
for a page that is to render a form accept it as an optional parameter to its
initializer

```ruby {4-6}
# app/src/front_end/pages/preferences_page.rb
class PreferencesPage < AppPage

  def initialize(form: nil)
    @form = form || UserPreferencesForm.new
  end

  def page_template
    # ...
  end
end
```

We'll then use `@form`, along with Brut's API to generate the HTML.  While not
required, surrounding our form with the `<brut-form>` custom element is a good
practice, which we'll see in another HOWTO.

To create the `<form>` tag, we'll use `Brut::FrontEnd::Components::FormTag`, which is available in Phlex views
via `FormTag`

```ruby {9-13}
# app/src/front_end/pages/preferences_page.rb
class PreferencesPage < AppPage

  def initialize(form: nil)
    @form = form || UserPreferencesForm.new
  end

  def page_template
    brut_form do
      FormTag(for: @form) do
        # ...
      end
    end
  end
end
```

This ensures the form will be submitted to the route we configured.  Now, we'll generate the HTML.  This
example will show only minimal HTML to get the form working, but will include the correct markup for validation 
errors (though we won't use them in this HOWTO).

To generate HTML for the form elements, we'll use included Brut components that live in
`Brut::FrontEnd::Components::Inputs`.  These can be accessed directly from `Inputs::`, e.g. `Inputs::InputTag`.
We'll also use the `Brut::FrontEnd::Components::ConstraintViolations` component which will include markup
useful for validation errors.

```ruby {11-29}
# app/src/front_end/pages/preferences_page.rb
class PreferencesPage < AppPage

  def initialize(form: nil)
    @form = form || UserPreferencesForm.new
  end

  def page_template
    brut_form do
      FormTag(for: @form) do
        label do
          Inputs::InputTag(form: @form,     input_name: :account_name)
          span { "Account Name" }
          ConstraintViolations(form: @form, input_name: :account_name)
        end

        label do
          Inputs::InputTag(form: @form,     input_name: :default_num_tasks)
          span { "Default # of Tasks" }
          ConstraintViolations(form: @form, input_name: :default_num_tasks)
        end

        label do
          Inputs::InputTag(form: @form,     input_name: :default_public)
          span { "Public by Default?" }
          ConstraintViolations(form: @form, input_name: :default_public)
        end

        button { "Save Preferences" }
      end
    end
  end
end
```

## Handle the Submission

When the form is submitted, it will be submitted to `/user-preferences`. The values will be placed into an
instance of `UserPreferencesForm`, and that instance can be made available to `UserPreferencesHandler` for
processing.

> [!NOTE]
> Because `UserPreferencesForm` is a class with defined attributes, any values submitted with the form that aren't explicitly declared in `UserPreferencesForm` will be discarded. No need for "strong" attributes or an allowlist of inputs

`brut scaffold` created `app/src/front_end/handlers/user_preferences_handler.rb`
where we can put our logic. For this HOWTO, we'll just save the data into a
database table called `USER_PREFERENCES`

Handlers are initialized with whatever values they need to work. Handlers need the
form instance, so in our case, we'll just accept that in the initializer.

```ruby {2-4}
class UserPreferencesHandler < AppHandler
  class initialize(form:)
    @form = form
  end

  def handle
    # ..
  end
end
```

Next, we'll implement `handle` which is called by Brut to actual do the handling.
It's return value controls what happens next.  In this case, we'll redirect back to
the page with the form, `PreferencesPage`.

```ruby {6-13}
class UserPreferencesHandler < AppHandler
  class initialize(form:)
    @form = form
  end

  def handle
    DB::UserPreferences.create(
      account_name: @form.account_name,
      default_num_tasks: @form.default_num_tasks,
      default_public: @form.default_public
    )
    redirect_to(PreferencesPage)
  end
end
```

## Show Default Values in HTML

Not all forms are blank by default. In our running example, it would make sense for
the `PreferencesPage` to show the values from the `DB::UserPreferences` entry
instead of blank values.

All form classes have an initializer that accepts the key `params:`, which is a
hash of values to use as defaults. We can do this in the initializer of
`PreferencesPage`.

```ruby {4-15}
# app/src/front_end/pages/preferences_page.rb
class PreferencesPage < AppPage

  def initialize(form: nil)
    @form = if form 
              form
            else
              existing_preferences = DB::UserPreferences.first
              UserPreferencesForm.new(params: {
                account_name: existing_preferences&.account_name,
                default_num_tasks: existing_preferences&.default_num_tasks,
                default_public existing_preferences&.default_public:
              })
            end
  end

  def page_template
    # ...
  end
end
```

The `page_template` method doesn't need to change - the use of `Inputs::InputTag` will see that the form has a value for a given input and use that.
