# Keyword Injection

Brut is desiged around classes and objects, as compared to modules and DSLs.  Almost everything you do when building your app is to create a class that has an initializer and implements one or more methods.  But, these classes often need information from the request that Brut is managing.

In a basic Rack or Sinatra app, you would access this information via Rack's API, which is essentially a Hash of Whatever. It's error-prone and requires consulting documentation, source code, or runtime information to figure out what's stored where.

Brut can instead inject these values explicitly into the classes of yours it creates.  It does this based on the
names of keyword arguments declared by your class' intializer.

## Overview

A [Page](/pages) may need the session, flash, HTTP headers, query string parameters, or placeholder values from the URI.  These can all be provided by declaring them as keyword arguments to the page's initializer:

```ruby
clas WidgetsByIdPage < AppPage
  def initialize(id:,                # ":id" from /widgets/:id
                 session:,           # AppSession instance for this request
                 flash:,             # Flash for this request
                 http_user_agent:,   # Value of User-Agent header
                 compact:)           # query string param "compact"

    # ...
  end
end
```

Brut uses this technique in multiple places.  It allows you to design classes whose
dependencies are clear and explicit, but without having to dig around into hashes or
manually construct higher-level objects.


### Standard Injectible Information

In any request, the following information is available to be injected:

| Value                      | Always Present?                                                                                                                                                                                                    | Description                                                                                     |
| ---                        | ---    | ----                                                                                            |
| `session:`                 | ✅ Yes | An instance of your app's `Brut::FrontEnd::Session` subclass for the current visitor's session. |
| `flash:`                   | ✅ Yes | An instance of your app's `Brut::FrontEnd::Flash` subclass.                                                                                                                                                        |
| `xhr:`                     | ✅ Yes | true if this was an Ajax request.                                                                                                                                                                                  |
| `body:`                    | ✅ Yes | the body submitted, if any.                                                                                                                                                                                        |
| `csrf_token:`              | ✅ Yes | The current CSRF token.                                                                                                                                                                                            |
| `clock:`                   | ✅ Yes | A `Clock` to be used to access the current time in the visitor's time zone.                                                                                                                                        |
| `http_*`                   | ❌ No  | any parameter that starts with `http_` is assumed to be for an HTTP header. For example, `http_accept_language` would be given the value for the "Accept-Language" header.  See the section on HTTP headers below. |
| `rack_request_*:`          | ❌ No  | Any value from the [`Rack::Request`](https://rubydoc.info/gems/rack/3.1.16/Rack/Request) or, more likely, from the [`Helpers`](https://rubydoc.info/gems/rack/3.1.16/Rack/Request/Helpers) module.                 |
| `env:`                     | ✅ Yes | The Rack env.  This is discouraged, but available if you can't get what you want directly                                                                                                                          |
| `form:`                    | ❌ No  | The [form](/forms) that was submitted, for [handlers](/handlers) only                                                                                                                                              |
| Any query string parameter | ❌ No  | For [pages](/pages) only                                                                                                                                                                                           |
| Any route placeholder      | ✅ Yes | For [pages](/pages) and [handlers](/handlers)                                                                                                                                                                      |

#### Route Hooks

[Route hooks](/hooks) are slightly different.  They have access to only these
values:

| Name               | Always Present? | Description                                                                                                                      | 
| ---                | ---             | --- |
| `request_context:` | ❌ No           | The current `Brut::FrontEnd::RequestContext`, thought it may be `nil` if the hook runs before `Brut::FrontEnd::InlineSvgLocator` |
| `session:`         | ✅ Yes          | An instance of your app's `Brut::FrontEnd::Session` subclass for the current visitor's session.                                  |
| `request:`         | ✅ Yes          | The Rack request                                                                                                                 |
| `response:`        | ✅ Yes          | The Rack response                                                                                                                |
| `env:`             | ✅ Yes          | The Rack env.                                                                                                                    |

#### HTTP Headers

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

### Injecting Custom Data

The true power of keyword injection is that you can store your own data into the
request context and have it injected into classes when Brut instantiates them.

The place to do this is in a [before hook](/hooks), since that happens before any
page or handler is created, but *after* the `Brut::FrontEnd::RequestContext` is
created (which is where all of this information is stored).

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

Note that the value is only injected if it exists.  It's important not to inject `nil` for values that don't exist.

With this in place, any page that requires an authenticated account can declare it:

```ruby
class PreferencesPage < AppPage
  def initialize(authenticated_account:)
    # ...
  end
end
```

If the request context has no value for `authenticated_account`, the page cannot be
instantiated.  Thus, the page's code can always rely on a non-`nil` value for
`authenticated_account` (provided you don't inject `nil`).

> [!WARNING]
> Do not inject `nil` into the request context.  Brut currently allows
> it, but may prevent it in a future update. `nil` is no good for nobody.

### When Values Aren't Available

When a value is not available for injection, and the keyword doesn't provide a default, Brut will raise an error.  This is because
such a situation represents a design error.

The tables above document which values should always be available. You should never
provide a default value for these, e.g. `session:` or `env:`. For values that are
not always available, you should provide a default value unless you are sure there
will be no routing to the page or handler without the value set.

This is most important for query string parameters.  Since a user can easily
manipulate these, if your page accepts, say, the parameter `use_detailed_view`, but
that parameter isn't present, Brut will not be able to instantiate your page unless
`use_detailed_view:` has a default value in the initializer's keyword arguments.

See [route hooks](/hooks).

## Testing

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

* **Do not provide default values when Brut documents the value is always
available**
  - If your page needs the session, it will always be there. Don't default `session:` to some other value (especially `nil`!)
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
