# Brut's High Level Architecture

Brut attempts to have parity with the web platform in general, and how web browsers work.  For example, a web browser shows you a web
page, thus to do this in Brut, you create a page class.

Brut's core ethos is to captialize on fundamental knowledge you must already posses to build a web app, such as HTML, JavaScript, the
Web Platform, SQL, etc.

The best way to understand Brut is to break down how a request is handled.

## HTTP Requests at a High Level

1. HTTP Request is received
2. If the request's route is mapped, handle it and return the result
3. Otherwise, 404

This pretty much describes every web app server in the world.  Let's dig into step 2

## Pages, Forms, Actions

HTML allows for exactly two ways to interact with a server: Issuing a `GET` for a resource (like a web page), or submitting a form via
a `GET` or `POST`.

1. HTTP Request is received
2. If the route is a mapped page, render that page
3. If the route is a configured form, submit that form handle it
4. If the route is an asset like CSS or an image, send that.
5. Otherwise, 404

A browser can use JavaScript to submit other requests, and Brut handles those, too:

1. HTTP Request is received
2. If the route is a mapped page, render that page (See {file:doc-src/pages.md})
3. If the route is a configured form, submit that form handle it (See {file:doc-src/forms.md})
4. If the route is a configured action, perform it and return the results. (See {file:doc-src/handlers.md})
5. If the route is an asset like CSS or an image, send that. (See {file:doc-src/assets.md})
6. Otherwise, 404

Before we dig deeper, it's worth pointing out at this point that *Brut is not an MVC framework*, mostly because there are no
controllers.  *Models* in the MVC sense are instead *pages* or *components*—classes that provide all dynamic behavior and data needed
to render some HTML.  Brut uses ERB templates to generate HTML and you could think of this as the view, if you want.

## Back End

Most of Brut is concerned with what it calls the *front end*, which is everything about receiving an HTTP request and producing the
reponse.  But you can almost never make a web app with no back end.  You almost always need a database and a place to execute logic
outside of a web browser.  Brut refers to this as the *back end*.

Since web back ends are less constrained to protocols, like a front end is to HTTP and other Web APIs, Brut provides a lot less for
the back end and puts many fewer restrictions on it.  This ends up being a good thing, since the back-end of most web apps are were
most of the differentiation in behavior and logic tend to be.

Brut provides access to a SQL database via the Sequel Ruby library.  Brut provides some integration with Sidekiq, to allow running
background jobs. Brut also provides a CLI library for creating one-off tasks (like you'd use Rake for in a Rail apps).

### SQL

Almost all web apps that have a database use SQL.  And Postgres is a great choice.  This is the SQl database that Brut supports,
though support for other databases may be added later. This is because almost all of Brut's SQL integration is via the Sequel library
and it supports many databases.

Brut provides some configuration for Sequel to make managing your data easier and to better-support practices that you often want
to follow.  For example:

* All tables have a primary key of type `int` by default.
* All tables have a `created_at` field that is set on row insertion.
* Timestamps use `timestamp with time zone`.
* You must provide a comment to document all tables.
* You can have Brut manage an external unique key for each table, so you can keep your primary keys private.
* `find!` is available on Sequel models, working like `find` does in Rails.

See {file:doc-src/sql.md} for more details.

Brut also uses Sequel's model support to provide access to your database.  It is configured to namespace all models in the `DB::`
namespace, so if you have a table named `widgets`, Brut will expect `DB::Widget` to be defined to access that table.

The reason for this is that it is often confusing when an app conflates the concept of a database table and a domain model, it can be
difficult to manage the code.  If the model to access the `widgets` table were called, simply, `Widget`, then you would lose a great
class name to use for modeling the widget as a domain object.

### Sidekiq

Sidekiq can be added to any app without much fanfare.  That said, Brut provides a few convieniences:

* `bin/run-sidekiq` is provided to run Sidekiq alongside your web app
* {Brut::SpecSupport::RSpecSetup} well arrange for Sidekiq to be set up in a useful way during tests:
  - For non-E2E tests, jobs are cleared between test runs.
  - During E2E tests, actual Sidekiq is used, as started by `/bin/run-sidekiq`, and jobs are cleared between tests.

### CLI / Tasks

Rake is not a great tool for task automation, mostly because it exposes a cumbersome command line interface that relies on environment
variables, square brackets, and commas.  It's often easier to create a full-blown command line app.

Brut's {Brut::CLI::App} can form the basis for any command line app or task you need for your system.  It provides access to Brut
internals and your app, as needed, and shares much of its startup code with your web app, ensuring parity for all code shared.

Brut's CLI support also allows for an expedient definition of a subcommand-style UI that behaves like a canonical UNIX command line
app, without having to write a lot of code.  It wraps `OptionParser`, so if you are familiar with this library that's part of Ruby,
you will be familiar with Brut's CLI API.

See {file:doc-src/cli.md}.
