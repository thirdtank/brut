# Keyword Injection

Brut is desiged around classes and objects, as compared to modules and DSLs.  Almost everything you do when creating your app is to
create a class that has an initializer and implements one or more methods.  But these initalizers and methods often need information
from the request that Brut is managing.

In a basic Rack or Sinatra app, you would access stuff like query parameters or the session by using Rack's API.  This can be tedious
and error-prone.  Brut will inject certain values into your class based on the keyword arguments of the initializer or method.

For example, a {file:doc-src/pages.md Page} requires you to implement an initializer. That initializer's keyword arguments define what
information is needed. Brut provides that information. This is a form of dependency injection and it can simplify your code if used
effectively.

Consider this route:

    page "/widgets/:id"

Brut will expect to find `WidgetsByIdPage`.  Your initializer can declare `id:` as a keyword arg and this will be passed when the
class is created:

    class WidgetsByIdPage < AppPage
      def initialize(id:)
        @widget = DB::Widget.find(id)
      end
    end

There are many more values that can made available.  For example, suppose you accept the query string parameter "compact" that
controls some rendering of the page.  To access it, declare it as a keyword arg (being sure to set a default value since it may not be available):

    class WidgetsByIdPage < AppPage
      def initialize(id:, compact: false)
        @widget  = DB::Widget.find(id)
        @compact = compact
      end
    end

## Standard Injectible Information

In any request, the following information is available to be injected:

* `env:` - The Rack env.
* `session:` - An instance of your app's {Brut::FrontEnd::Session} subclass for the current visitor's session.
* `flash:` - An instance of your app's {Brut::FrontEnd::Flash} subclass.
* `xhr:` - true if this was an Ajax request.
* `body:` - the body submitted, if any.
* `csrf_token:` - The current CSRF token.
* `clock:` - A {Clock} to be used to access the current time in the visitor's time zone.

Depending on the context, other information is available:

* `form:` - If a form was submitted, this is the {Brut::FrontEnd::Form} subclass containing the data. See {file:doc-src/forms.md Forms}.
* Any query string paramter - Remember, these should have default values or Brut will raise an error if they are not provided.
* Any route parameter - These should not have default values, since they are required for Brut to match the route.

A {Brut::FrontEnd::RouteHook} is slightly different. Only the following data is available to be injected:

* `:request_context` - The current request context, thought it may be `nil` depending on when the hook runs
* `session:` - An instance of your app's {Brut::FrontEnd::Session} subclass for the current visitor's session.
* `:request` - The Rack request
* `:response` - The Rack response
* `env:` - The Rack env.

You can also use the request context to put your own data that can be injected.

## Injecting Custom Data

The general lifecycle of a request is that any before hook is run, then the page or action is triggered, then after actions.  Thus, to
inject your own data, such as the currently authenticated visitor, you would use a before hook:

    class AppSession < Brut::FrontEnd::Session
      def logged_in?
        !!self.authenticated_account
      end
      def authenticated_account
        # look up the account data model 
        # based on e.g. self[:account_id]
      end
    end

    class AuthBeforeHook < Brut::FrontEnd::RouteHook
      def before(request_context:,session:,request:,env:)
        if session.logged_in?
          request_context[:authenticated_account] = session.authenticated_account
        end
        continue
      end
    end

Once you do this, you can use `authenticated_account:` as a keyword argument to any page, handler, or global component:

    class DashboardPage < AppPage
      def initialize(authenticated_account:)
        @widgets = authenticated_account.widgets # e.g.
      end
    end

While this won't handle authorization for you, you can be sure that when `DashboardPage` is used, there is an `authenticated_account`
available.

## `nil` and Empty Strings

When a keyword argument has no default value, Brut will require that value to exist and be available for injection. If the keyword is
not one of the canned always-available values, it will look in the request context, then in the query string.

If the request has the keyword as a key, *it will inject whatever value it finds, including `nil`*.  In general, you should avoid
injecting `nil` when you actually intend to not have a value.

For example, the `AuthBeforeHook` above, you could implement it like so:

      request_context[:authenticated_account] = session.authenticated_account

The problem is that if the visitor is not logged in, the `:authenticated_account` *will* have a value, and that value will be `nil`.
This is almost certainly not what you want.

For query string parameters, the HTTP spec says that they are strings.  Thus, if a query string parameter is present in ther request
URL, it will *always* have a value and *never* be `nil`.  If the paramter doesn't have a value after the `=` (e.g. for `foo` in `?foo=&bar=quux`), the value will be the empty string.

This means you must write code to explicitly handle the cases you care about.

## When Values Aren't Available

When a value is not available for injection, and the keyword doesn't provide a default, Brut will raise an error.  This is because
such a situation represents a design error.

For example, the `DashboardPage` above requires an `authenticated_account`.  Your app should never route a logged-out visitor to that
page.  This allows the `DashboardPage` to avoid having to check for `nil` and figure out what to do.

This is most relevant for query string parameters, since they can be easily manipulated by the visitor in their browser.  Query string
parameters should always have a default value, even if it's `nil`.

*Path* parameters (like `:id` in `WidgetsByIdPage`) should *never* have a default value as their absence means a different URL was
requested.  For example, `/widgets` would trigger a `WidgetsPage`. *Only* if the `:id` path parameter is present would the
`WidgetsByIdPage` be triggered, so it's safe to omit the default value for `id:` (and pointless to include one).

See {file:docs-src/route-hooks.md}

## Design For Injection

Consider a method like so:

    def create_widget(name:, organization: nil, quantity: 10)

Outside of Brut, the way to interpret this arguments is as follows:

* `name` is required
* `organization` is optional
* `quantity` has a default value of 10 if not provided

Any method or intializer that will be keyword-injected should be designed with this in mind.  Thus, the following guidelines will be
helpful in managing your app:

* **Choose arguments based on the needs of the class:**
  - If a value is optional, default it to either `nil` or a symbol that indicates what happens when the value is omitted
  - If an optional value has a default, use that (this should be rare for pages, handlers, components, and hooks)
  - Otherwise, do not provide a default for the keyword
* **Do not inject `nil` into the request context.** When your code requires a value for a keyword, you want to rely on that value being non-nil.  Thus, avoid injecting `nil` into the request context. Brut will allow it as a sort-of escape hatch, but you should design your app to avoid it
* **Be careful injecting global data.**  The request context instance is per request, but you could certainly put global data into it. For example, you may put an initialized API client into the request context as a convieniece. **Be careful** because your app is multi-threaded.  Any object that is not scoped to the request must be thread-safe.
