# Quick Tour of Brut's Features

## Pages

A [*Page*](/pages) models, well, a web page. It's a class that holds all the data
necessary to generate its HTML as well as a method called `page_template`, which
generates the HTML via Phlex.

A page's routing is convention-based and starts with a URL:

```ruby{6}
class App < Brut::Framework::App
  def id           = "my-app"
  def organization = "my-org"

  routes do
    page "/dashboard"
  end
end
```

This URL means our page class is expected in `DashboardPage`.

```ruby
class DashboardPage < AppPage
  def initialize
    @now     = Time.now
  end

  def page_template
    main do
     h1 { "Hello!" }
     h2 do
       plain("It's ")
       time(datetime: l(@now, format: iso_8601)) do
         l(@now, format: date)
       end
     end
    end
  end
end
```

This would all produce HTML like so, depending on the value of 

```html [/dashboard]
<main>
  <h1>Hello!</h1>
  <h2>It's
    <time datetime="2025-02-17">
      Monday, Feb 17
    </time>
  </h2>
</main>
```

Note that the actual HTML delivered would include the code for a layout.

## Layouts

Brut includes the concept of [layouts](/layouts), and they work similar to Rails.
Layouts are classes, however, and implement the Phlex-standard `view_template`
method:

```ruby
class DefaultLayout < Brut::FrontEnd::Layout
  def initialize(page_name:)
    @page_name = page_name
  end

  def view_template
    doctype
    html(lang: "en") do
      head do
        meta(charset: "utf-8")
        link(rel: "preload", as: "style", href: asset_path("/css/styles.css"))
        link(rel: "stylesheet",           href: asset_path("/css/styles.css"))
        script(defer: true, src: asset_path("/js/app.js"))
        title { app_name }
      end
      body do
        yield
      end
    end
  end
end
```

This produces this HTML:

```html
<!DOCTYPE html>
<html>
  <head>
    <meta charset="utf-8">
    <link rel="preload" as="style" href="/css/styles-«HASH».css">
    <link rel="stylesheet" href="/css/styles-«HASH».css">
    <script defer src="/js/app-«HASH».js">
    <title>My Awesome App</title>
  </head>
  <body>
    <-- page HTML here -->
  </body>
</html>
```


## Components

*Components* are a way to manage the complexity of HTML generation. The are Phlex components, meaning they are a class that implements `view_template`.

Here's an example of a flash message component:

```ruby
# components/flash_component.rb
class FlashComponent < AppComponent
  def initialize(flash:)
    if flash.notice?
      @message_key = flash.notice
      @role = :info
    elsif flash.alert?
      @message_key = flash.alert
      @role = :alert
    end
  end

  def any_message? = !@message_key.nil?

  def view_template
    if any_message?
      div(role: @role) do
        t([ :flash, @message_key ])
      end
    end
  end
end
```

You can then use this in any other view using `render`, provided by Phlex.

```ruby
def page_template
  header do
    render FlashComponent.new(flash:)
  end
end
```

## Forms

[*Forms*](/forms) are a major concept like pages, since they are the way a browser
submits data to the server.

In Brut, a form does three things:

* Describes the data in the `<form>` tag
* Implies a route where its data is submitted via HTTP POST
* Provides access to the submitted data (via an object with methods, not a Hash of Whatever)

Like `page`, `form` declares a form's route:

```ruby{2}
routes do
  form "/login"
end
```

Brut is convention-based, so it will expect a class named `LoginForm` to exist. It
will also expect `LoginHandler` to exist, which is a class that will receive the
form submission and process it. More on handlers below.

`LoginForm` uses class methods to declare its inputs.  These class methods mirror
the various form element tags in HTML (`input`, `select`, etc.), and the methods
attributes allow you to declare names and client-side constraints:

```ruby [forms/login_form.rb]
class LoginForm < AppForm
  input :email
  input :password, minlength: 8
end
```

An instance of this class can be used to create HTML:

```ruby
def view_template
  FormTag(for: @form) do
    Inputs::InputTag(form: @form, input_name: :email)
    Inputs::InputTag(form: @form, input_name: :password)
    button { "Login" }
  end
end
```

> [!NOTE]
> We'll explain what `FormTag` and `Inputs::InputTag` are in the [forms
> section](/forms)

This generates this HTML:

```html
<form action="/login" method="POST">
  <input type="email" name="email" required>
  <input type="password" name="password" required minlength="8">
  <button>Login</button>
</form>
```

When the form is submitted, an instance of `LoginForm` is created and made available
to `LoginHandler`

## Handlers

A handler is like a controller in Rails, except it only has one method: `handle`.
Unlike a Rails controller, a handler class is given its arguments explicitly, and
`handle`'s return value dictates what will happen next.

```ruby
class LoginHandler < AppHandler
  def initialize(form:)
    @form = form
  end
  def handle
    if @form.email == "secret@example.com" &&
       @form.password = "sup3rs3cret!"
       redirect_to(DashboardPage)
    else
      form.server_side_constraint_violation(
        input_name: :email,
        key: :no_such_user
      )
      LoginPage.new(form:)
    end
  end
end
```

Note that we access the form's values as methods, not by digging into a Hash of
Whatever.  Also note that returning an instance of a page will generate that page's
HTML, much like Rails' `render :edit` might.  Lastly, `redirect_to` is a
convenience to generate a URL to `DashboardPage`, and ultimately causes `handle` to
return a `URI`, which Brut interprets as a redirect.


## JavaScript

Brut doesn't include a front-end framework, however you can certainly use one.  All
JavaScript is bundled into a single bundle by [esbuild](https://esbuild.github.io/).

Brut includes [BrutJS](/brut-js), which is a collection of autonomous custom
elements AKA Web Components that provide convenient features like autosubmit, form
submission confirmation and more:

```ruby{5,7}
def view_template
  FormTag(for: @form) do
    Inputs::InputTag(form: @form, input_name: :email)
    Inputs::InputTag(form: @form, input_name: :password)
    brut_confirm_submit(message: "Really login? In this economy?!") do
      button { "Login" }
    end
  end
end
```

When "Login" is pressed, `window.confirm` will ask if the visitor wants to proceed.
This custom element can also use a `<dialog>` that you style, and works even better
if that `<dialog>` makes use of `<brut-confirmation-dialog>`.

## CSS

Brut includes [BrutCSS](/css#using-brut-css), which is a lightweight utility-based
CSS library to let you get started quickly. It's *not* TailwindCSS, nor will it ever
be.

You can replace it with whatever you like easily enough.


## Database Schema

Brut provides access to an SQL database via Sequel.  Brut uses Sequel's database schema management, however it is enhanced to
encourage good practices by default.

> [!NOTE]
> Brut currently *only supports* PostgreSQL.  It may support all RDBMSes that Sequel supports, but as of now,
> it's just Postgres.

Consider a `households` table that relates to an `accounts` table.

```ruby
create_table :households,
             comment: "Family unit managing the data" do
  column :timezone, :text
  column :dinner_time_of_day, :text
  constraint(
    :time_must_be_time,
    %{
      (dinner_time_of_day ~ '^[01][0-9]:[0-5][0-9]$') OR
      (dinner_time_of_day ~ '^2[0-3]:[0-5][0-9]$')
    }
  )
end

create_table :accounts,
             comment: "People or systems who can access this system",
             external_id: true do

  column :email,             :email_address, unique: true
  column :deactivated_at,    :timestamptz, null: true
  foreign_key :household_id, :households
end
```

This is mostly using [Sequel's built-in migrations API](https://sequel.jeremyevans.net/rdoc/files/doc/schema_modification_rdoc.html).  But, a few additional behaviors are happening:

* Columns default to `NOT NULL`
* Tables require comments
* Foreign keys default to having constraints and indexes

There are other quality-of-life features of Brut's migration system, all designed to default to a good practice, with a way to do it
however you want when needed.

## Database Access

Brut uses `Sequel::Model` to access data in your database.  To discourage the conflation of "models of database tables" with "models
of your application's domain", these classes are in the `DB` namespace.  Thus, the class `DB::Household` would be able to access the
`households` table defined above. This frees you up to create a `Household` class to model your domain's logic without being coupled
to how you store some data in a database.

```ruby
class DB::Account < AppDataModel
  has_external_id :ac
  many_to_one :household
end

class DB::Household < AppDataModel
  one_to_many :accounts
end
```

## Domain and Business Logic

Brut uses Zeitwerk for code loading, so any directories you create will be auto-loaded and refreshed during development.  This means that you can create a class named `Household` in `app/src/back_end/domain/household.rb` and it would be loaded.  Or, you could create `HouseholdService` in `app/src/back_end/services/household_service.rb` if you like.

> [!TIP]
> Providing a generally-useful abstraction for business or domain logic is not usually feasible.
> Thus, Brut doesn't provide much beyond Zeitwerk's auto-loading feature.  It may provide more
> assistance in  the future, but for now, Brut's approach is to free you from any prescription
> or moral imperative. Manage your domain and business logic how you see fit. You know your domain
> and team better than we do.

## Testing

Brut provides support for three types of tests:

* Unit Tests, using RSpec
* End-to-end tests, using RSpec and Playwright
* Custom Element tests, written in JavaScript, using Mocha

Since Brut is based on classes, objects, and methods, your unit tests will usually
be straightforward, however Brut provides helpers to test your Page and Component
HTML using Nokogiri.  FactoryBot is included and configured to manage test data.

## Tasks

Brut doesn't use Rake tasks. It uses CLI apps powered by Ruby's `OptionParser`.  Brut provides bootstrapping classes to make your own CLIs, as well as some light abstractions to make `OptionParser` a little more ergonomic.  Brut's dev and production management CLIs are built using this support.

## Observability

Brut has built-in support for [OpenTelemetry](https://opentelemetry.io/).  Brut includes configuration for the [otel-desktop-viewer](https://github.com/CtrlSpice/otel-desktop-viewer) or a text-based viewer suitable for development.  For production, most observability vendors provide OpenTelemetry ingestion any many have free tiers.

Brut does support logging, however you are encouraged to use OpenTelemetry instead.

