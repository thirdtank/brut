# Keyword Injection

Brut is desiged around classes and objects, as compared to modules and DSLs.  Almost everything you do when building your app is to create a class that has an initializer and implements one or more methods.  But, these initalizers and methods often need information from the request that Brut is managing.

In a basic Rack or Sinatra app, you would access this information via Rack's API, which is essentially a `Hash` of whatever. It's error-prone and requires consulting documentation, source code, or runtime information to figure out what's stored where.

Brut can instead inject these values explicitly into the classes of yours it creates.  It does this based on the
names of keyword arguments declared by your class' intializer or a template method Brut will call.

## Overview

For example, a [Page](/pages) requires you to implement an initializer. That initializer's keyword arguments define what
information is needed. Brut provides that information when it creates the object. This is a form of dependency injection and it can simplify your code if used effectively.

Consider this route:

```ruby
page "/widgets/:id"
```

Brut will expect to find `WidgetsByIdPage`.  Your initializer can declare `id:` as a keyword arg and this will be passed when the
class is created:

```ruby
class WidgetsByIdPage < AppPage
  def initialize(id:)
    @widget = DB::Widget.find(id)
  end
end
```

If the page requires access to the session, it can declare that:

```ruby {2,4}
class WidgetsByIdPage < AppPage
  def initialize(id:, session:)
    @widget       = DB::Widget.find(id)
    @current_user = session.current_user
  end
end
```

Because `session:` is a required argument, Brut cannot instantiate the page without it, so it will always be
passed in and availbale.

### Standard Injectible Information

In any request, the following information is available to be injected:

* `session:` - An instance of your app's `Brut::FrontEnd::Session` subclass for the current visitor's session.
* `flash:` - An instance of your app's `Brut::FrontEnd::Flash` subclass.
* `xhr:` - true if this was an Ajax request.
* `body:` - the body submitted, if any.
* `csrf_token:` - The current CSRF token.
* `clock:` - A `Clock` to be used to access the current time in the visitor's time zone.
* `http_*` - any parameter that starts with `http_` is assumed to be for an HTTP header. For example, `http_accept_language` would be
given the value for the "Accept-Language" header.  See the section on HTTP headers below.
* `env:` - The Rack env.  This is discouraged, but available if you can't get what you want directly

Depending on the context, other information is available:

* `form:` - If a form was submitted, this is the `Brut::FrontEnd::Form` subclass containing the data. See [Forms](/forms).
* Any query string paramter - Note that if these conflict with existing Brut values, the behavior is undefined.  Name your query string parameters carefully. These should have default values or your page won't work if they are omitted.
* Any route parameter - These should not have default values, since they are required for Brut to match the route.

A `Brut::FrontEnd::RouteHook` is slightly different. Only the following data is available to be injected:

* `request_context:` - The current request context, thought it may be `nil` depending on when the hook runs
* `session:` - An instance of your app's `Brut::FrontEnd::Session` subclass for the current visitor's session.
* `request:` - The Rack request
* `response:` - The Rack response
* `env:` - The Rack env.

### HTTP Headers

Since any header can be sent with a request, Brut allows you to access them, including non-standard ones.  Rack (which is based on CGI), provides access to all HTTP headers in the `env` by taking the header name, replacing dashes ("-") with underscores ("\_"), and prepending `http_` to the name, then uppercasing it.  Thus, "User-Agent" becomes `HTTP_USER_AGENT`.

Because Ruby parameters and variables must start with a lower-case letter, Brut uses the lowercased version of the Rack/CGI variable.
Thus, to receive the "User-Agent", you would declare the keyword parameter `http_user_agent`.

Further, because headers come from the client and may not be under your control, the value that is actually injected depends on a few
things:

* If your keyword arg is required, i.e. there is no default value:
  - If the header was not provided, `nil` is injected.
  - If the header *was* provided, it's value is injected, even if it's the empty string.
* If your keyword arg is optional, i.e.  it has a default value
  - If the header was not provided, no value is injected, and your code will receive the default value.
  - If the header *was* provided, it's value is injected, even if it's the empty string.

### Ordering and Disambiguation

You are discouraged from using builtin keys for your own data or request parameters.  For example, you should not have a query string
parameter named `env` as this conflicts with the builtin `env` that Brut will inject.

Since you can inject your own data (see below), you are free to corrupt the request context.  Please don't do this. Brut may actively
prevent this in the future.

You can also use the request context to put your own data that can be injected.

### Injecting Custom Data

The correct place to inject your own data into the request is in a [before hook](/hooks).  When you
configure a before hook, it will run after Brut's internal
`Brut::FrontEnd::RouteHooks::SetupRequestContext`, which ensures the request context exists and is ready
for use.

For example, here is how you might inject the currently logged-in account based on the session:

```ruby
class AuthBeforeHook < Brut::FrontEnd::RouteHook
  def before(request_context:,session:)
    if session.authenticated_account
      request_context[:authenticated_account] = session.authenticated_account
    end
    continue
  end
end
```

Note that the value is only injected if it exists.  It's important not to inject `nil` for values that
don't exist.

You may be thinking that this particular example is unnecessary. You could simply inject `session:` and
call `session.authenticated_account`:

```ruby
class DashboardPage < AppPage
  def initialize(session:)
    @widgets = session.authenticated_account.widgets # e.g.
  end
end
```

If `DashboardPage` requires an authenticated account, by only injecting the session, you'll need to handle the case where `session.authenticated_account` is `nil`.  Instead, if you configure the `AuthBeforeHook` as above, then inject `authenticated_account`, you avoid the need for this logic:

```ruby
class DashboardPage < AppPage
  def initialize(authenticated_account:)
    @widgets = authenticated_account.widgets # e.g.
  end
end
```

Because `AuthBeforeHook` never injects `nil`, `DashboardPage` can rely on `authenticated_account` always being present.  Further, if a visitor tried to access `/dashboard_page` without having been authenticated, Brut would be unable to create an instance of `DashboardPage` and generate an error.

### `nil` and Empty Strings

When a keyword argument has no default value, Brut will require that value to exist and be available for injection. If the keyword is
not one of the canned always-available values, it will look in the request context, then in the query string.

If the request has the keyword as a key, *it will inject whatever value it finds, including `nil`*.  In general, you should avoid
injecting `nil` when you actually intend to not have a value.

For example, the `AuthBeforeHook` above, you could implement it like so:

```ruby
request_context[:authenticated_account] = session.authenticated_account
```

The problem is that if the visitor is not logged in, the `:authenticated_account` *will* have a value, and that value will be `nil`. This is almost certainly not what you want.

For query string parameters, the HTTP spec says that they are strings.  Thus, if a query string parameter is present in ther request
URL, it will *always* have a value and *never* be `nil`.  If the paramter doesn't have a value after the `=` (e.g. for `foo` in `?foo=&bar=quux`), the value will be the empty string.

This means you must write code to explicitly handle the cases you care about.

### When Values Aren't Available

When a value is not available for injection, and the keyword doesn't provide a default, Brut will raise an error.  This is because
such a situation represents a design error.

For example, the `DashboardPage` above requires an `authenticated_account`.  Your app should never route a logged-out visitor to that
page.  This allows the `DashboardPage` to avoid having to check for `nil` and figure out what to do.

This is most relevant for query string parameters, since they can be easily manipulated by the visitor in their browser.  Query string
parameters should always have a default value, even if it's `nil`.

*Path* parameters (like `:id` in `WidgetsByIdPage`) should *never* have a default value as their absence means a different URL was
requested.  For example, `/widgets` would trigger a `WidgetsPage`. *Only* if the `:id` path parameter is present would the
`WidgetsByIdPage` be triggered, so it's safe to omit the default value for `id:` (and pointless to include one).

See [route hooks](/hooks).

### Testing

Brut will not create your classes in a test.  Instead, you must pass in the values you want.  There are various
helpers in `Brut::SpecSupport` to create blank or empty versions of the special classes.

In particular, A basic `request_context` is setup per test and injected into the Thread local storage. This means
that if your test should trigger a codepath that *does* cause Brut to use keyword injection, useful values will
be injected.

For your tests, however, you should pass in directly what you need:

```ruby
page = WidgetsByIdPage.new(id: widget.id, session: empty_session)
```

## Recommended Practices

Consider a method like so:

``` ruby
def create_widget(name:, organization: nil, quantity: 10)
```

Outside of Brut, the way to interpret this arguments is as follows:

* `name` is required
* `organization` is optional
* `quantity` has a default value of 10 if not provided

Any method or intializer that will be keyword-injected should be designed with this in mind.  Thus, the following guidelines will be helpful in managing your app:

* **Choose arguments based on the needs of the class:**
  - If a value is optional, default it to either `nil` or a symbol that indicates what happens when the value is omitted
  - If an optional value has a default, use that (this should be rare for pages, handlers, components, and hooks)
  - Otherwise, do not provide a default for the keyword
* **Design for non-`nil` values instead of allowing `nil` and checking for it**
  - If a page needs, say, the currently logged-in user, set that up as injectible with no default.
  - If a codepath creates that page without the logged-in user, you will get a very obvious error and
    can figure out how it happened. Your page's code doesn't need to figure out what to do with `nil`
* **Do not inject `nil` into the request context.** When your code requires a value for a keyword, you want to rely on that value being non-nil.  Thus, avoid injecting `nil` into the request context. Brut will allow it as a sort-of escape hatch, but you should design your app to avoid it
* **Be careful injecting global data.**  The request context instance is per request, but you could certainly put global data into it. For example, you may put an initialized API client into the request context as a convieniece. **Be careful** because your app is multi-threaded.  Any object that is not scoped to the request must be thread-safe.

## Technical Notes

> [!IMPORTANT]
> Technical Notes are for deeper understanding and debugging. While we will try to keep them up-to-date with changes to Brut's
> internals, the source code is always more correct.

_Last Updated May 7, 2025_

Keyword injection is currently implemented in a few places and not available via public API.  It could be useful
as an API and it will be exposed at some point. For now, it's only available for Brut-managed classes as
documented here.
