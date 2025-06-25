# Routes

The primary function of a web framework like Brut is to map URLs requested by the browser or an HTTP client and invoke code based on
them.

Brut has a fairly simple routing system. It's not desgined to be flexible—it's designed to make the most common cases you
will need as straigthforward as possible.

## Overview

### Route Syntax

A route is a string that contains the path part of a [URL](https://developer.mozilla.org/en-US/docs/Web/API/URL).  *Segments* of the
path (i.e. the stuff between each forward slash `/`) can be either *static* or a *placeholder*.  The route is given as a parameter to
a method that indicates the purpose of the route (e.g. `page`), and these two factors determine the  name of the class that will
handle requests to that route.

Specifically:

* Only the [pathname](https://developer.mozilla.org/en-US/docs/Web/API/URL/pathname) of a request may be specified.
* All routes must start with a slash
* The segements of the pathname may be static or placeholders. Placeholders must be a valid Ruby keyword argument prepended with a
colon.
* Routes may not start with a placeholder.

Some examples:

```
"/dash_board"
"/widgets/:id"
"/company/:company_id/locations/:location_id"
"/"
```

### Specifying Routes

As mentioned above, routes are passed to methods that determine their purpose.  There are currently four types of routes, and thus
four possible methods you would use to configure them:

|Method|Purpose| HTTP Method | More Info |
|------|-------|-------------|-----------|
|`page` | Specifies a web page at that route | `GET` | [Pages](/pages) |
|`form` | Indicates a form will exist and post its form data to this route | `POST` | [Forms](/pages) |
|`action` | Indicates a form with no form data will exist and post to this route | `POST` | [Handlers](/handlers) |
|`path` | This route will respond to an arbitrary HTTP method, which must be specified as an additional parameter | Any | [Handlers](/handlers) |

Brut is designed around generating HTML.  HTML provides the ability to navigate to new web pages via `GET`, or submit data to the
server from a `<form>` via `POST`.  That is why three of the four methods are focused on these use-cases.

To specify routes, you can call these methods inside the `routes do` block of your `App` class, located in `app/src/app.rb`:

```ruby{6-9} [app/src/app.rb]
class App < Brut::Framework::App
  def id           = "my-app"
  def organization = "my-org"

  routes do
    page   "/widgets/:id"
    form   "/new_widget"
    action "/archive_widget/:id"
    path   "/widget_payment_received", method: :put
  end
end
```

> [!NOTE]
> Brut does not use an abstraction like resources to manage the routes of your web app.
> Few non-programmers know what a resource is, so the routing API is designed to match
> concepts a non-programmer can observe or identify, like URLs, forms, and pages.

### Connecting Routes to Code

Brut is convention-based, so the routes you specify, and the method you pass them to, determine the class that will handle the
request.  For `page` routes, Brut will locate a page class (see [Pages](/pages)), which will be used to
render the web page.  All other routes will be managed by a handler (see [Handlers](/handlers)), which are somewhat like a controller
in Rails, but with only a single method.

The name of the class is determined as follows:

* Static segments of the pathname are mapped to namespaces or a class based on converting the path segment to camel-case. For example `new_widget` becomes `NewWidget`.
* The final static segment in the path represents a class name.  All other static segments represent modules in which the final class is namespaced
  - If the route is for a page, `Page` is appended to the class name.
  - If the route is for a form, there are two classes in play, one appended with `Form` and one with `Handler`.
  - If the route has no form and is just a handler, `Handler` is appended to the class name.
* Placeholder segments are attached to the previous static segment, augmenting its name:
  - The placeholder is camel-cased
  - The placeholder is prefixed with `By` for `page` routes and `With` for all other routes
  - the prefixed-placeholder is appended to the previous module or class name, e.g. `WidgetsById`
* These are now connected to form a valid Ruby class name.
* The route `/` is special and always maps to `HomePage`.

The examples in the previous section demonstrate how this works:

| Route | Class name |
|-------|------------|
| `page   "/widgets/:id"` | `WidgetsByIdPage` |
| `form   "/new_widget"` | `NewWidgetForm` and `NewWidgetHandler`
| `action "/archive_widget/:id"` | `ArchiveWidgetByIdHandler`
| `path   "/widget_payment_received", method: :put` | `WidgetPaymentReceivedHandler`

Note that deeply nested routes that contain several placeholders will work, and create complicated classnames.

```ruby
page "/company/:company_id/location/:location_id"
# => CompanyByCompanyId::LocationByLocationIdPage
```

> [!TIP]
> If you don't like long complicated names, deeply-nested namespaces, and long directory names, name your routes accordingly.

### Creating URIs from Routes

Because each route is associated with a class, you can use the class to create the route, including any placeholders and query string
parameters.

The most direct way to do this is with the `routing` method available on each page or handler class:

```ruby
> WidgetsByIdPage.routing(id: 42)
# => /widgets/42
> WidgetsByIdPage.routing(id: 42, compact: true)
# => /widgets/42?compact=true
> ArchiveWidgetByIdHandler.routing(id: 42)
# => /archive_widget/42
```

If you fail to provide the required parameters, `routing` will raise a `Brut::Framework::Errors::MissingParameter` with a message
explaining the problem.

```ruby
> begin
    WidgetsByIdPage.routing
  rescue Brut::Framework::Errors::MissingParameter => ex
    puts.ex.message
  end
# => Parameter 'id' was not available. Received params: no params.
#    :id was used as a path parameter for
#    WidgetsByIdPage (path '/widgets/:id')
```

`routing` is how you create links to other pages:

```erb
<a href="<%= DashBoardPage.routing %>">
  Go to Dashboard
</a>
```

> [!NOTE]
> You can use `routing` to create `<form>` actions, but `form_tag`, which we'll discuss in [Forms](/forms), can do this for you.

The `routing` method isn't an abstraction around routes. It's more of a strongly-typed translation.  This means when you change
something, your app won't route to non-existent routes—it'll blow up with a helpful error.

For example, if you decided that `/dash_board/` should've been called `/account_home`, you would change the value in `app.rb`, then
rename the class.  At this point, any code that routes to `DashboardPage.routing` will raise a `NameError`.  With sufficient test coverage, you can address everywhere you see the `NameError` and be confident you have changed the name and route successfully.

## Testing

Routes are configuration, so you do not need to test them.  Your end-to-end tests will ensure your links and form actions are working, and your page tests will ensure any routes they generate in HTML are valid.

## Recommended Practices

Brut does not provide flexibility with routes.  For example, you cannot specify an optional placeholder.  While this may change, Brut
is designed to isolate logic to classes like pages, forms, hooks, middlewares, or handlers.  Brut does not want logic to exist at the
routing layer.

Beyond these technical limitations, here are some recommendations regarding routes.

### Routes Should be Named for Concepts Anyone Can Understand

You don't need your routes to be the names of models or database tables.  If you have an account management page that allows modifying data in a table called `user_preferences`, but everyone just calls it "the account management page", the route should be `/account_management`.

Although routes are primarily for programmers to manage, there's no reason not to name them using the terms everyone involved in your
app uses.  This is part of the reason Brut inserts `By` or `With` when there is a placeholder.  It allows you to have a page for all
widgets—the "widgets page"—and a page for a specific widget by id—the "widgets by id page".

### Prefer Shallow Routes with a Single Placeholder

The more path segments your route has, and the more placeholders it is, the longer your class name will be and the more you lose the
connection to reality.  The "company by company id location by location id page" doesn't exactly roll off the tongue.

Life will be easier if you can choose names and routes that have a single placeholder.  Multiple path segments can be useful for
namespacing.

### Placeholders Identify Things, Query Strings Search for Things

You could certainly have a `/widgets` route, and then look at a query string parameter named `id` to know what widget to show.  This
is likely not what you want.  If a route should always identify a specific thing in your back-end, it should have a placeholder where
that thing's identifier goes.

If a route allows searching for things with multiple optional critiera, a query string is more appropriate.  This is the HTTP spec, so
if you follow its guidelines, you'll be fine.

### Pluralization Is Up to You

The rules Brut uses to determine the class names to handle routes do not rely on pluralization.  You can have a `/widget` route and a `/widgets` route, if that makes sense to your domain and team.  They are both handled by the same set of underlying rules.

## Technical Notes

> [!IMPORTANT]
> Technical Notes are for deeper understanding and debugging. While we will try to keep them up-to-date with changes to Brut's
> internals, the source code is always more correct.

_Last Updated Feb 23, 2025_

Brut stores all configured routes in a `Brut::FrontEnd::Routing` object.
This means that all metadata about a route is available.  You are not intended to interact with this class, but you will note that in
certain circumstances, the `Brut::FrontEnd::Routing::Route` can be injected into your class.

Brut uses this metadata to create route handlers with Sinatra.  While Brut may not always use Sinatra  under the covers, it does as of
the writing, so when you call `page "/widgets"`, Brut will call `get "/widgets" do` and pass a block to Sinatra to find the class to
handle the reqest, create an instance of it, call a method on it, and return the response.


