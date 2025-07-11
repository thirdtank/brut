# Routes

The primary function of a web framework like Brut is to map URLs requested by the browser or an HTTP client and invoke code based on them.

Brut has a fairly simple routing system that's not designed for flexibility.

## Overview

Your app has a subclass of `Brut::Framework::App`, called `App`. It includes a call
to the `routes` class method.  In there, you declare your routes by using one of
four methods:

| Method                           | HTTP Method | Purpose                                                                                       |
|----------------------------------|-------------|-----------------------------------------------------------------------------------------------|
| `page «route»`                   | GET         | Declare a page                                                                                |
| `form «route»`                   | POST        | Declare a form to be submitted to a handler                                                   |
| `action «route»`                 | POST        | Declare an element-less form to be submitted to a handler (akin to Rails' `button_to` helper) |
| `path «route», method: «method»` | `«method»`  | Declare an arbitrary path to a handler                                                        |

The value for `«route»`, along with the method called, is used to determine what
class(es) will be used to handle the route.

### «route» Syntax

A route is a string that contains the *path part* of a [URL](https://developer.mozilla.org/en-US/docs/Web/API/URL).  *Segments* of the path (i.e. the stuff between each forward slash `/`) can be either *static* or a *placeholder*.

As such:

* Only the [pathname](https://developer.mozilla.org/en-US/docs/Web/API/URL/pathname) of a request may be specified.
* All routes must start with a slash
* A placeholder segment must be a valid Ruby identifier preceded by a colon, e.g.
`:company_id` is allowed, but `:company-id` is not.
* Routes may not start with a placeholder.

Some examples:

```
"/dash_board"
"/widgets/:id"
"/company/:company_id/locations/:location_id"
"/"
```

### Class Naming Conventions

Brut is convention-based, so you are not able to specify the name of the classes
used to handle routes.  Brut will use the method you called (e.g. `page`) and the
route your provided to determine the class name.

Some examples:

| Route invocation                              | Expected Class Name(s)             |
|-----------------------------------------------|------------------------------------|
| `page "/dashboard"`                           | `DashboardPage`                    |
| `page "/widgets/:id"`                         | `WidgetsByIdPage`                  |
| `form "/login"`                               | `LoginForm` and `LoginHandler`     |
| `action "/delete_widget/:id"`                 | `DeleteWidgetWithIdHandler`        |
| `path "/tokens/personal/:token, method :put"` | `Tokens::PersonalWithTokenHandler` |

Specifically, the name of the class(es) is/are determined as follows:

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

Note that deeply nested routes that contain several placeholders will work, and create complicated classnames.

```ruby
page "/company/:company_id/location/:location_id"
# => CompanyByCompanyId::LocationByLocationIdPage
```

> [!NOTE]
> All routes can receive query string parameters. These are not factored
> into the name of the class that will handle the route, but they
> *are* made available to your Page or Handler.

### Creating URIs for Routes

Because each route is associated with a class, you can use the class to create the route, including any placeholders and query string
parameters.

The most direct way to do this is with the `routing` method available on each page or handler class:

```ruby
> WidgetsByIdPage.routing(id: 42)
# => /widgets/42
> WidgetsByIdPage.routing(id: 42, compact: true)
# => /widgets/42?compact=true
> WidgetsByIdPage.routing(id: 42, compact: true, anchor: "summary")
# => /widgets/42?compact=true#summary
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
> You can use `routing` to create `<form>` actions, but `Brut::FrontEnd::Components::FormTag`, which we'll discuss in [Forms](/forms), can do this for you.

The `routing` method isn't an abstraction around routes. It's more of a strongly-typed translation.  This means when you change
something, your app won't route to non-existent routes—it'll blow up with a helpful error.

For example, if you decided that `/dash_board/` should've been called `/account_home`, you would change the value in `app.rb`, then
rename the class.  At this point, any code that routes to `DashboardPage.routing` will raise a `NameError`.  With sufficient test coverage, you can address everywhere you see the `NameError` and be confident you have changed the name and route successfully.

## Testing

Routes are configuration, so you do not need to test them.  In fact, you can't test them directly. Your end-to-end tests should adequately cover the correct usage of your routes. If you always using `.routing` to generate routes, Ruby's runtime checks will also ensure you have not used a non-existent or invalid route.

## Recommended Practices

Brut does not provide flexibility with routes, nor is logic intended to exist where
you are declaring them.

### Routes Should be Named for Concepts Anyone Can Understand

If you have an account management page that allows modifying data in a table called `user_preferences`, but everyone just calls it "the account management page", the route should be `/account_management`.

Although routes are primarily for programmers, there's no reason not to name them using the terms everyone involved in your app uses.  This is part of the reason Brut inserts `By` or `With` when there is a placeholder.  It allows you to have a page for all widgets—the "widgets page"—and a page for a specific widget by id—the "widgets by id page".

### Prefer Shallow Routes with a Single Placeholder

The more path segments your route has, and the more placeholders it is, the longer your class name will be and the more you lose the
connection to reality.  The "company by company id location by location id page" doesn't exactly roll off the tongue.

Life will be easier if you can choose names and routes that have a single placeholder.  Multiple path segments can be useful for namespacing.

### Placeholders Identify Things, Query Strings Search for Things

A query string is for just that: querying. The query string is not for identifying
things.  That's what URIs are for.

As such, for routes where a specific *thing* is being identified, use route
placeholders like `/widgets/:id`. When a route is used for searching or locating
*things*, a query string is better: `/widgets?type=«type»`.

Remember that the query string is *not* part of the class name. The values for the
query string will be made available to your page or handler.

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


