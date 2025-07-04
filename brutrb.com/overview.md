# Conceptual Overview

Brut is a web framework that provides the ability to receive HTTP requests and respond to them.  It includes facilities for generating HTML, interacting with a database, managing assets and more. Pretty much everything you need, though not much that you don't.

Brut's approach and design are built on three core values:

* **Leverage Standards** - The web platform is great, and Brut wants you to use it.
* **There's One Best Way To Do It** - Flexibility leads to chaos.
* **Simple over Easy** - Verbose code that can be quickly understood beats impenetrable compact DSLs every day.

As such, Brut's API and concepts are intended to mirror concepts that exist in the domain of building web sites.  For example, when you go to a URL, you are viewing a web page. In Brut, a page is rendered by using a subclass of `Brut::FrontEnd::Page`, called a *page*.

Brut also avoids creating abstractions on top of existing standards you already need to know to build websites.  For example, instead of creating a resource/verb abstraction on top of submitting forms over HTTP, Brut instead has you implement a `Brut::FrontEnd::Form` that describes the form's inputs—just like you'd have in HTML.

## Basic Elements of a Brut-Powered App

Below is a diagram showing the high level parts of a Brut app.  It shows four important terms with respect to how
Brut is organized:

* *Client* or *Client Side* is the web browser (or HTTP client). This is where CSS is applied to HTML and where JavaScript is executed. HTTP requests are initiated here.
* *Server* or *Server Side* is where any code not in the browser runs. In Brut, this includes HTML generation, SQL queries, and everything in between.
* *Front End* is the code that deals with producing your user interface or HTTP API.  A lot of this code runs on
the *server side*, however it exists to provide a user interface of some sort.
* *Back End* is the code that deals with everything else, such as accessing a database, executing business logic, or managing background jobs.


![Architectural Overview](/images/OverviewMetro.png)

* **Visitor** is someone visiting your web site or app.
* **Browser** is, well, a web browser
* [**Pages**](/pages) generate web pages, which is what happens when a browser's UI navigates to a URL.
* [**Forms**](/forms) describe the inputs of an HTML `<form>` element, and hold a form's submitted data for server-side processing. Browser submit forms to the server.
* [**Components**](/components) generate HTML fragments and are used to generate the HTML of a page or for re-use across pages.
* [**Handlers**](/handlers) receive non-GET HTTP requests from the browser, notably form submissions.
* [**JavaScript**](/javascript) and [**Assets**](/assets) (including [CSS](/css)) are bundled on the server and sent to the client.
* [**Domain Logic**](/business-logic) as where your business and domain logic lives and can be implemented however you like.
* [**DB Models**](/database-access) are objects that provide access to your database.
* **Relational Database** is your database, where data is stored.

## Brut is Not a Resource-Oriented MVC Framework.

You will note that Brut is *not* an MVC framework.  Rather than creating an often confusing abstraction on top of
HTTP, browsers, and HTML, Brut provides a more direct set of primitives.

Further, Brut is not *resource-oriented*.  While HTTP does include the concept of resources and verbs to operate
on those resources, in the context of building a web application, these two abstractions cause more problems than
they solve.

Although Brut can can certainly respond to any URL and any verb, the core set of abstractions mirror the observed behavior of a web browser: *Pages* generate HTML (with the help of *Components*). *Forms* describe data to collect from the user, which is submitted to *Handlers* for processing by the back-end.  Ajax requests (and arbitrary HTTP requests) can also be responded-to by *Handlers*.

In practice, this means that you do not have to perform mental gymnastics to decide exactly what verb and/or resource best represents the use-case you are trying to build.  When your partners want to build an "account management page", you will be able to implement this with a class named `AccountManagementPage`.  When discussing enhancements to the "user settings form", you will making changes to the `UserSettingsForm` and `UserSettingsHandler`. If that form is on the page everyone calls the "preferences page", you'll be dealing with `PreferencesPage`, and not "the index method of the `UserSettingsController`.

Let's go one step deeper to see how these primitives work.


## Quick Tour of Brut's Primitives

### Pages

The *Page* is the best example of Brut's value system.  When you fetch a URL in a web browser, that is referred to as a web page.
Thus, in Brut, a route accessed via an HTTP `GET` is managed by an instance of a *page class*.

Instead of a routing system where you must map http-like verbs to resource, Brut's routes are more direct.  For a page, you'd use the `page` method (we'll explain more what `class App` and `routes do` are doing later):

```ruby{5-7}
class App < Brut::Framework::App
  def id           = "my-app"
  def organization = "my-org"

  routes do
    page "/dashboard"
  end
end
```

Brut is convention-based, so when this route is requested by the browser, Brut will instantiate the class `DashboardPage` to handle the request.  The page is an enhanced Phlex component that supports layouts.  You implement `page_template` and make calls to Phlex's API to generate your page's HTML.

You will write an initializer (using keyword arguments) that describes all the data your page needs in order to
generate its HTML.  Brut will instantiate your page class into an object and use Phlex's API to generate HTML.

There is great variety in what your initializer can be given by Brut. For example, if we want to show the current time as well as respond to the query-string parameter "compact", we'd write our class like so:

::: code-group

```ruby [pages/dashboard_page.rb]
class DashboardPage < AppPage
  def initialize(clock:, compact: false)
    @now     = clock.now
    @compact = compact != "true"
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
     if !@compact
       p { "Do you know where your web framework is?" }
     end
    end
  end
end
```

```ruby [layouts/default_layout.rb]
class DefaultLayout < Brut::FrontEnd::Layout
  def view_template
    doctype
    html do
      head do
        title { "My Awesome Site" }
        body do
          yield
        end
      end
    end
  end
end
```
:::

This would all produce HTML like so:

::: code-group
```html [/dashboard]
<!DOCTYPE html>
<html>
  <head>
    <title>My Awesome Site</title>
  </head>
  <body>
    <main>
      <h1>Hello!</h1>
      <h2>It's
        <time datetime="2025-02-17">
          Monday, Feb 17
        </time>
      </h2>
      <p>
        Do you know where your web framework is?
      </p>
    </main>
  </body>
</html>
```

```html [/dashboard?compact=true]
<!DOCTYPE html>
<html>
  <head>
    <title>My Awesome Site</title>
  </head>
  <body>
    <main>
      <h1>Hello!</h1>
      <h2>It's
        <time datetime="2025-02-17">
          Monday, Feb 17
        </time>
      </h2>
    </main>
  </body>
</html>
```
:::

### Components

*Components* are a way to manage the complexity of HTML generation.  A component is exactly like a page: it's Phlex Component that powers dynamic HTML generation.  The only difference is that a page has a *layout*, whereas a component does not.

In the example below, a flash is passed into `FlashMessage` by Brut and `t` translates a string. More on both of those later. Note the components use Phlex API more directly by asking you to implement `view_template`.  Brut tries to defer or mimic APIs of standard libraries classes rather than create its own wrappers unless there is a compelling reason.

```ruby
# components/flash_message.rb
class FlashMessage < AppComponent
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
    if !@message_key.nil?
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
    render FlashMessage.new(flash:)
  end
end
```

### Forms

To allow data to be submitted from the browser, you'd use an HTML `<form>` that contains many `<inputs>`, as has been the case since
the birth of the web.  To declare a form that will be submitted, use `form`:

```ruby{2}
  routes do
    form "/login"
  end
```

Brut is convention-based, so it will expect a class named `LoginForm` to exist to hold a programmatic description of the form.  This description allows the form's data to be managed during the submission process.  That form is passed to an instance of `LoginHandler`, which contains the logic for processing the submission.

The idea behind form classes is to avoid dealing with Hashes containing magical strings or symbols and instead deal with a more strictly defined type.  This means, among other benefits, you don't have maintain a separate list of allowed parameters. Your form defines them and is used to generate HTML, so it's all just one list of parameters.  Forms aren't that fancy, though. Just as HTML `FormData` is string keys and string values, so it is with Brut forms.

To define the inputs, class methods are used in the form class' definition.  When the form is submitted `LoginHandler#handle` is called, and passed an instance of the form.  The form has methods to access the inputs' values

::: code-group
```ruby [forms/login_form.rb]
class LoginForm < AppForm
  input :email
  input :password
end
```

```ruby [handlers/login_handler.rb]
class LoginHandler < AppHandler
  def handle(form:)
    # form.email    => value from <input name=email>
    # form.password => value from <input name=password>
  end
end
```
:::

A handler is like a controller in Rails, except it only handles one action.  The `handle` method's return value indicates what should happen.  For example, you may want to re-validate the client-side constraints. If any have been violated, you'd want to re-generate the HTML for the `LoginPage`. If everything looks good, you'll redirect to the `DashboardPage`:

```ruby{3-7}
class LoginHandler < AppHandler
  def handle(form:)
    if form.constraint_violations?
      LoginPage.new(form:)
    else
      redirect_to(DashboardPage)
    end
  end
end
```

### JavaScript and CSS

Brut does not include a front-end framework, however it doesn't prevent you from using one.  Brut *does* include a configuration of esbuild that will serve you well for most situations. esbuild is also configured to bundle and manage your CSS.  This, coupled with recent advancements in CSS means that you don't need something like SASS.  You can use standard `@import` statements to manage your CSS across multiple files and use CSS nesting to namespace your classes.

Brut provides a JavaScript *library* called BrutJS. BrutJS is mostly a set of custom elements that act as HTML Web Components, progressively enhancing markup you manage and style with common behaviors. Some of these components are used to provide localized messaging for client-side constraint violations.  You can use these with any other client-side framework, or just use them on their own. You can also skip using them entirely and provide your own solution.

### Database Schema

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
             comment: "People or systems who can access this system", external_id: true do
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

### Database Access

Brut uses `Sequel::Model` to access data in your database.  To discourage the conflation of "models of database tables" with "models
of your application's domain", these classes are in the `DB` namespace.  Thus, the class `DB::Household` would be able to access the
`households` table defined above. This frees you up to create a `Household` class to model your domain's logic without being coupled
to how you store some data in a database.

### Domain and Business Logic

Brut uses Zeitwerk for code loading, so any directories you create will be auto-loaded and refreshed during development.  This means that you can create a class named `Household` in `app/src/back_end/domain/household.rb` and it would be loaded.  Or, you could create `HouseholdService` in `app/src/back_end/services/household_service.rb` if you like.

> [!TIP]
> Providing a generally-useful abstraction for business or domain logic is not usually feasible.
> Thus, Brut doesn't provide much beyond Zeitwerk's auto-loading feature.  It may provide more
> assistance in  the future, but for now, Brut's approach is to free you from any prescription
> or moral imperative. Manage your domain and business logic how you see fit. You know your domain
> and team better than we do.

### Testing

Brut provides support for three types of tests:

* Unit Tests, using RSpec
* End-to-end tests, using RSpec and Playwright
* Custom Element tests, written in JavaScript, using Mocha

Since almost every class you create is a plain Ruby class, testing the classes is usually straightforward.  That said, it's often
better to test Pages and Components through their generated HTML. Brut provides help to do that, based on Nokogiri.

### Tasks

Brut doesn't use Rake tasks. It uses CLI apps powered by Ruby's `OptionParser`.  Brut provides bootstrapping classes to make your own CLIs, as well as some light abstractions to make `OptionParser` a little more ergonomic.  Brut's dev and production management CLIs are built using this support.

### Observability

Brut has built-in support for OpenTelemetry.  Brut includes configuration for the otel-desktop-viewer or a text-based viewere suitable for develompent.  For production, most observability vendors provide OpenTelemetry ingestion any many have free tiers.

Brut does support logging, however you are encouraged to use OpenTelemetry instead.

## Directory Structure

At the top level:

| Directory | Purpose |
|-----------|---------|
| `app/`    | Contains all configuration and source code specific to your app |
| `bin/`    | Contains tasks and other CLIs to do development of your app, such as `bin/test` |
| `dx/`     | Contains scripts to manage your development environment |
| `specs/`  | Contains all tests |

Inside `app`/

| Directory | Purpose |
|-----------|---------|
| `bootstrap.rb` | A ruby file that sets up your app and ensures everything is `require`d in the right way. |
| `config/` | Configuration for your app, such as localizations and translations. Brut tries very hard to make sure there is no YAML in here at all. YAML is not good for you. |
| `public/` | Root of public assets served by the app. |
| `src/` | All source code for your app |

Inside `app/src`

| Directory | Purpose |
|-----------|---------|
| `app.rb` | The core of your app, mostly configuration, such as routes, hooks, middleware, etc. |
| `back_end/` | Back end classes for your app including database schema, DB models, seed data, and your domain logic |
| `cli/` | Any CLIs or tasks for your app |
| `front_end/` | The front-end for your app, including pages, components, forms, handlers, JavaScript, and assets |

Inside `app/src/back_end`

| Directory | Purpose |
|-----------|---------|
| `data_models/app_data_model.rb` | Base class for all DB model classes |
| `data_models/db` | DB model classes |
| `data_models/db.rb` | Namespace module for DB model classes |
| `data_models/migrations` | Database schema migrations |
| `data_models/seed` | Seed data used for local development |

Inside `app/src/front_end`

|Directory       | Purpose |
|----------------|---------|
| `components/`  | Component classes |
| `css/`         | CSS, managed by esbuild and `bin/build-assets` |
| `fonts/`       | Custom fonts, managed by esbuild and `bin/build-assets` |
| `forms/`       | Form classes |
| `handlers/`    | Handler classes |
| `images/`      | Images, copied to `app/public` by `bin/build-assets` |
| `js/`          | JavaScript, managed by esbuild and `bin/build-assets` |
| `layouts/`     | Layout classes |
| `middlewares/` | Rack Middleware, if any |
| `pages/`       | Page classes |
| `route_hooks/` | Route hooks, if any |
| `support/`     | General support classes/junk drawer. |
| `svgs/`        | SVGs you want to render inline |


