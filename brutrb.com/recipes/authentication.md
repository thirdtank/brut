# Authentication Example

It's impossible to account for all types of authentication you may want to use, but
this recipe will demonstrate all the moving parts:

* How to require authentication for some pages
* How to design pages that require authentication
* How to manage the signed-in user in code

## Feature

* Visitors can log in with an email, that is assumed to have been inserted previously (no passwords or signup, just to simplify the recipe)
* Visitors can access the home page without logging in
* Visitors cannot access the dashboard page without logging in

## Recipe

### Set up Database and Seed Data

First, we'll make a database table called `accounts` that will have an email field
and a password hash field.

```
bin/db new-migration accounts
```

This will create a file in `app/src/back_end/data_models/migrations`.  We'll edit it
to create a new table called `accounts`:

```ruby
Sequel.migration do
  up do
    create_table :accounts, comment: "People or systems who can access this system", external_id: true do
      column :email, :text, unique: true
      column :deactivated_at, :timestamptz, null: true
    end
  end
end
```

We'll also create `app/src/back_end/data_models/db/account.rb`:

```ruby
class DB::Account < AppDataModel
  has_external_id :a3 # !IMPORTANT: Make sure this is unique amongst your DB models
end
```

Next, we'll create a factory for it in `specs/factories/db/account.factory.rb`:

```ruby
require "bcrypt"
FactoryBot.define do
  factory :account, class: "DB::Account" do
    email         { Faker::Internet.unique.email }
    trait :inactive do
      deactivated_at { Time.now }
    end
  end
end
```

Next, we'll make seed data in `app/src/back_end/data_models/seed/app_seed_data.rb`

```ruby
require "brut/back_end/seed_data"
class AppSeedData < Brut::BackEnd::SeedData
  include FactoryBot::Syntax::Methods
  def seed!
    create(:account,            email: "pat@example.com")
    create(:account, :inactive, email: "chris@example.com")
  end
end
```

Now, let's apply this to the database and load the seed data:

```
> bin/db migrate
> bin/db migrate -e test
> bin/db seed
```

### Create a Login Page

To make this UI work, we'll need a login page and a dashboard page.

```
> bin/scaffold page /login
> bin/scaffold page /dashboard
```

We'll also need a login form:

```
> bin/scaffold form /login
```

We'll add a link on the HomePage to log in:

```ruby
# app/src/front_end/pages/home_page.rb
class HomePage < AppPage
  def page_template
    h1 { "Welcome!" }
    a(href: LoginPage.routing) {
      "Log in"
    }
  end
end
```

Before building the login page, we'll need the form.  It'll just have one field:
email:

```ruby
# app/src/front_end/forms/login_form.rb
class LoginForm < AppForm
  input :email # Brut will make this type=email and required
end
```

Now, we can create the login page:

```ruby
# app/src/front_end/pages/login_page.rb
class LoginPage < AppPage

  include Brut::FrontEnd::Components

  # An existing form can be passed in, so that this
  # page can be shown with form errors from a previous
  # login attempt
  def initialize(form: nil)
    @form = form || LoginForm.new
  end

  def page_template
    h1 { "Login, please!" }
    brut_form do
      FormTag(for: @form) do
        label do
          Inputs::InputTag(form: @form, input_name: :email)
          div { "Email" }
          ConstraintViolations(form: @form, input_name: :email)
        end
        button do
          "Login"
        end
      end
    end
  end
end
```

Let's style the constraint violations in `app/src/front_end/css/index.css`:

```css
/* app/src/front_end/css/index.css */
brut-cv {
  display: none;
}

brut-cv[server-side],
brut-form[submitted-invalid] brut-cv {
  display: block;
  color var(--red-300);
}
```

Now, you can click on "Login", and you should see a client-side error message.

### Handle Logins

Now, we'll build out the login handler.  An email must exist and be active to be
allowed in.

```ruby
# app/src/front_end/handlers/login_handler.rb
class LoginHandler < AppHandler
  def initialize(form:, session:, flash:)
    @form    = form
    @session = session
    @flash   = flash
  end

  def handle
    if !@form.constraint_violations? # no client-side issues
      account = DB::Account.find(email: @form.email, deactivated_at: nil)
      if !account
        @form.server_side_constraint_violation(
          input_name: :email,
          key: :no_such_account
        )
      end
    end
    if @form.constraint_violations?
      LoginPage.new(form: @form)
    else
      @session.login!(account:)
      redirect_to(DashboardPage)
    end
  end
end
```

Hopefully, this logic is straightforward.  We'll need to allow `AppSession` to
implement `login!`.  We'll also need to have it fetch the `DB::Account` from the
session, we'll add that, too.

```ruby
# app/src/front_end/support/app_session.rb
class AppSession < Brut::FrontEnd::Session
  def login!(account:)
    self[:account_id] = account.id
  end
  def account
    DB::Account.find(id: self[:account_id])
  end
end
```

Now, we can build the dashboard page to greet them.  Instead of injecting the
session, however, we're going to inject the account as `current_account:`.  We'll
set this up in a minute.

```ruby
# app/src/front_end/pages/dashboard_page.rb
class DashboardPage < AppPage
  def initialize(current_account:)
    @current_account = current_account
  end

  def page_template
    h1 { "Dashboard" }
    h2 { "Hello #{@current_account.email}!" }
  end
end
```

### Injecting the Current Account

We want the current account to be in the `Brut::FrontEnd::RequestContext` if the
visitor is logged in.  We'll do that in a route hook.

First, we'll declare it in `App`:

```ruby
# app/src/app.rb
class App < Brut::Framework::App

  # ...

  before :SetupCurrentAccount

  # ...
end
```

Now, we can build the `SetupCurrentAccount` route hook.  Since it'll run after
`Brut::FrontEnd::RouteHooks::SetupRequestContext`, we can assume a `RequestContext`
will be available for injection. The session will be, too, of course:

```ruby
# app/src/front_end/hooks/setup_current_account.rb
class SetupCurrentAccount < Brut::FrontEnd::RouteHook
  def before(request_context:, session:)
    logged_in = !!session.account
    # NOTE: we do not insert nil. Either insert a value or don't insert.
    if logged_in
      request_context[:current_account] = session.account
    end
  end
end
```

At this point, the code we've written should work.  The only problem is that anyone
can access the Dashboard page. Granted, doing so without being logged in will cause
an error, but we don't want that.

### Requiring Login

To require login, we'll add to the `SetupCurrentAccount` hook we created. We want to
allow access to the login page as well as any Brut-owned paths.  If a logged-out
user access a restricted page, we'll redirect them to the login page.

```ruby
# app/src/front_end/hooks/setup_current_account.rb
class SetupCurrentAccount < Brut::FrontEnd::RouteHook
  def before(request_context:, session:)
    logged_in = !!session.account
    if logged_in
      request_context[:current_account] = session.account
    end

    is_login_page      = request.path_info.match(/#{Regexp.escape(LoginPage.routing)}/
    is_brut_owned_path = env["brut.owned_path"]

    path_requires_login = !is_login_page && 
                          !is_brut_owned_path

    if !logged_in && path_requires_login
      redirect_to(LoginPage)
    end
  end
end
```

And that's it!  The visitor should be redirected if they aren't logged in, but
should be allowed to restricted pages like the dashboard page if they are.

### You Don't Need Page Hooks for This

Implementing something like this in Rails would usually involve similar code to what
we just did, but pages requiring login would have some sort of `before_action`:

```ruby{2}
class WidgetsController < ApplicationController
  before_action :require_login!

  # ...
end
```

This could be shared in a parent page, but you essentially have to remember to do this on every page that requires login (or do the opposite - allow specific pages to be accessed without logging in).

In Rails, this is a good practice, because even though your views won't route a
logged-out visitor to a logged-in page, URL hacking or bugs could result in an
attempt to do so.  You need the failsafe.

In Brut, the very definition of the page's class includes the requirement for the
`current_account`. The page cannot be instantiated without it.

Thus, there is no need for a failsafe.  `SetupCurrentAccount` handles checking the
routes, and that's it.  If someone hacks a URL or a bug in the code sends a
logged-out visitor to the dashboard page, Brut literally cannot handle the request, since the `current_account` will be missing.
