# Route and Page Hooks

Route and page hooks allow you to perform logic or redirect the visitor before a page is rendered or action handled.

## Route Hooks

Route hooks are objects that are run before or after a request has been handled. They are useful for setting up cross-cutting code
that you don't want to have inside a page or handler.

To use one, call either {Brut::Framework::App.before} or {Brut::Framework::App.after}, passing it the *name* of a class to use as the
hook (i.e. a `String`).

Then, implement that class, extending {Brut::FrontEnd::RouteHook}, and provide either {Brut::FrontEnd::RouteHook#before} or {Brut::FrontEnd::RouteHook#after}.  As discussed in {file:doc-src/keyword-injection.md Keyword Injection}, your hook can be passed some managed values to allow it to work.

In general, a hook will allow the request to continue or not, but using one of the following methods as the return value:

* {Brut::FrontEnd::HandlingResults#redirect_to} to redirect the user instead of rendering the page or handling the request.
* {Brut::FrontEnd::HandlingResults#http_status} to return an HTTP status instead of rendering the page or handling the request.
* {Brut::FrontEnd::RouteHook#continue} to proceed with the request.

## Page Hooks

Sometimes, the behavior you want to manage before a page is rendered is specific to a page and not cross-cutting. Because a page
exepcts to render HTML, you cannot easily put such code in your page class.

If you implement {Brut::FrontEnd::Page#before_render}, you can skip page rendering entirely and redirect the user or send an error.  A
good example of this would be a set of admin pages where the logged-in site visitor must possess some roles in order to see the page.

A page hook expects one of these return values:

* `URI` - redirect the visitor instead of rendering the page.
* {Brut::FrontEnd::HttpStatus} - Send the browser this status code instead of rendering the page.
* Anything else - render the page as normal

Thus, the lifecycle of a page is:

1. "Before" Route Hooks
2. Page Initializer, injected as described in {file:doc-src/keyword-injection.md}
3. Page's `before_render`, called with no arguments.
4. Page's ERB generates HTML
5. "After" Route Hooks

## Handler Hooks

Like page hooks, handler hooks are called before handling logic.  Implement `before_handle`.  It's arguments must be a subset of the
arguments passed to `handle`.  Thus, any value needed by `before_handle` must be declared as a keyword argument to `handle` as well.

If `before_handle` returns `nil`, `handle` is then called.  Otherwise, `handle` is skipped and the return value of `before_handle` is
interpreted as the return value of `handle`. See {Brut::FrontEnd::Handler#handle}.

This makes the lifecycle of a handler as such:

1. "Before" Route Hooks
2. Handler Initializer, called with no argument.
3. Handler's `handle!`, injected with arguments as described in {file:doc-src/keyword-injections.md}
   1. `handle!` calls `before_handle`, passing the arguments in.
   2. `handle!` calls `handle`, passing the arguments in.
4. "After" Route Hooks

