# Pages

A core abstraction of Brut is the core concept of the web: the web page.

## Overview

To create a web page, you'll need:

* A [Route](/routes) using `page`.
* A class in `app/src/front_end/pages/` that extends `Brut::FrontEnd::Page`, named [conventionally](/routes#class-naming-conventions) (though in reality, your page willextend `AppPage` in `app/src/front_end/pages/app_page.rb`, which extends `Brut::FrontEnd::Page`).
* [Optional, but recommended] A test in `specs/front_end/pages`.

You can create all this with `bin/scaffold`, which accepts the route you want:

```shell
> bin/scaffold page /new_widgets
# => app/src/front_end/pages/new_widgets_page.rb
# => specs/front_end/pages/new_widgets_page.spec.rb
# => add `page "/new_widgets"` to app/src/app.rb
```

or

```shell
> bin/scaffold page /widget/:id
# => app/src/front_end/pages/widget_by_id_page.rb
# => specs/front_end/pages/widget_by_id_page.spec.rb
# => add `page "/widget/:id"` to app/src/app.rb
```

You can also perform these steps manually.

> [!WARNING]
> Adding a `page` route without the corresponding class may not always
> work, since Brut may try to load the class.  Brut does its best
> to avoid problems, but you should create your route and classes
> all at once

> [!IMPORTANT]
> Brut cannot currently reload new routes, so you must
> restart your dev server when you modify or add routes.

### Creating a Page

Pages need a `page_template` method that contains calls to Phlex, which will produce
the page's HTML.

If you have not used Phlex before, it's relatively straightfoward.  For each HTML
tag that exists, Phlex provides a method. So, for `<div>`, Phlex provides `div`.

Each method accepts parameters which are converted into attributes.  Methods can
also accept blocks that can be used to add more HTML by calling more of Phlex's API.

```ruby
class DashboardPage < AppPage
  def page_template
    header do
      h1 { "Welcome to My App!" }
      time { Date.today }
    end
    main do
      p(class: "body-text") do
        "This is my awesome app! I hope you stay awhile!"
      end
    end
  end
end
```

By default, this page will be rendered inside `DefaultLayout`, located in
`app/src/front_end/layouts/default_layout.rb` and discussed in [the layouts
module](/layouts).  The HTML this page will generate, that would then be inserted
into the layout's HTML, looks like so:

```html
<header>
  <h1>Welcome to My App!</h1>
  <time>2025-07-05</time>
</header>
<main>
  <p class="body-text">
    This is my awesome app! I hope you stay awhile!"
  </p>
</main>
```

### Accessing Data in a Page

Building static pages is fine, but not really why we use web app libraries.  Your
page is a normal class, so you can create instance variables and methods, which can
do whatever you need.

That being said, the initializer is called by Brut and can be given special
arguments.  For example, if your route has as placeholder, e.g. `/widgets/:id`, then
your initializer will be given the value of `:id` if its initializer has a keyword
argument named `id:`:

```ruby
def initialize(id:)
end
```

Query string parameters are also avaiable this way, but your page can access a wide
variety of request-level information simply by declaring a keyword argument to its
initializer.

This mechanism is called [keyword injection](/keyword-injection) and is available to many class you create, including pages.

Here is a list of what is available:

| Keyword Argument | Type | Description |
|-------|------|-------------|
`session:` | `Brut::FrontEnd::Session` (or your app's subclass) | The current session, even if it's empty. See [Flash and Session](/flash-and-session)|
`flash:` | `Brut::FrontEnd::Flash` (or your app's subclass) | The current flash, even if it's empty. See [Flash and Session](/flash-and-session) |
`xhr:` | `true` or `false` | true if this was an Ajax request|
`csrf_token:` | `String`| The current CSRF token. |
`clock:` | `Clock` | Used when you need to access the current date and time, potentially accounting for time zones.   See [Space/Time Continuum](/space-time-continuum)|
`http_*` | `String` or `nil` | Any parameter that starts with `http_` is assumed to be for an HTTP header. For example, `http_accept_language` would be given the value for the "Accept-Language" header. See [HTTP Headers](/keyword-injection#http-headers) |
`rack_request_*` | `String` or `nil` | Any parameter that starts with `rack_request_` is assumed to be for a value from the `Rack::Request`. For example, `rack_request_id` would provide the `ip` value from `Rack::Request` |
`env:` | `Hash` | The Rack env.  You are discouraged from using this directly in your pages, but if you need it, it's available. |
Placeholders | `String` | Any placeholder value from the route definition |
Any query string paramter | `String` | the value given is always a string.
Any object placed into the request context | `Object` | Values you place into the request context. See below for an example.

Thus, if `Admin::WidgetsByIdPage` responds to the `detail_level` query string parameter, needs access to the current time, wants to
check a value from the session, and responded to the completely made-up header "X-Be-Nice", the initializer would look like so:

```ruby
def initialize(id:,
               session:,
               clock:,
               http_x_be_nice:,
               detail_level: nil)
```

> [!CAUTION]
> Keyword arguments for query string parameters **must** have default values 
> or Brut will be unable to instantiate your page class when they are omitted.
> We recommended that **no other keywords arguments have defaults** to ensure your
> pages aren't created with `nil` values.

> [!NOTE]
> Omitting a default for an HTTP header is OK, but you should know what the behavior is. See [the HTTP Headers
> section](/keyword-injection#http-headers) for details.


### Page Hooks

Occasionally, you want to prevent a page from rendering after the visitor has been routed to it.  A common reason for this could be a lack of authorization by that visitor to view the page.

`before_generate` achieves this. It's called after construction, so has access to
any injected values, and its return value tells Brut what should happen:

* `URI` - the visitor will be redirected to the given URI.  Instead of creating a `URI`, you may use the method `redirect_to`, which
accepts a page and its parameters.
* `Brut::FrontEnd::HttpStatus` - the page will not be rendered and this status will be returned. You may use `http_status` to create
an `HttpStatus` from a number.
* `Brut::FrontEnd::GenericResponse` - a typed wrapper around the standard Rack response.
* Anything else - page rendering will proceed as usual.

## Testing

See [Unit Testing](/unit-tests) for some basic assumptions and configuration available for all Brut unit tests.

Although pages are Plain Old Ruby Objects, you likely want to test the HTML they
generate.  Brut provides convenience methods to do this based on Nokogiri.

### Generating a Response

* If your page has no before hook, or you aren't testing that, call `generate_and_parse(page_instance)`.  This returns a `Brut::SpecSupport::EnhancedNode`, which is a delegate to Nokogiri's `Nokogiri::XML::Node` (see below for why this exists)
* If you want to assert behavior of the before hook, call `generate_result`, which
will return whatever the page's internal `handle!` method called.
will use one of these matchers on the result:

### Asserting Results

When using `generate_and_parse`, you have access to all of Nokogiri, however
`Brut::SpecSupport::EnhancedNode` provides two methods to simplify your test:

```ruby
it "should work" do
  result = generate_and_parse(described_class.new)

  expect(result.e!("h1").text).to include("Welcome")
  expect(result.e("h2")).to       eq(nil)
end
```

* `e!` returns the node matching the given CSS selector, failing the test if there
is not exactly one matching node.
* `e` (no bang) returns the node matching the given CSS selector, or `nil` if none matched.  If there is more than one match, the test fails.

When using `generate_result`, you will want to use one of two special purpose
matchers:

```ruby
it "redirects" do
  result = generate_result(described_class.new)
  expect(result).to have_redirected_to(AuthPage)
end

it "404's" do
  result = generate_result(described_class.new)
  expect(result).to have_returned_http_status(404)
end
```

- `have_redirected_to` to check that a redirect happened to the URI you set (see `Brut::SpecSupport::Matchers::HaveRedirectedTo`)
- `have_returned_http_status` to check that a given HTTP response was returned (see `Brut::SpecSupport::Matchers::HaveReturnedHttpStatus`)

Beyond this, you can use Nokogiri as usual to navigate the DOM that's generated and
make assertions.  A few additional matchers to help are:

- `be_routing_for` - expect a URI to be a routing for a certain page or
page/parameter combination. See `Brut::SpecSupport::Matchers::BeRoutingFor`.
- `have_html_attribute` - check that a node has an attribute or an attribute with a
specific value. See `Brut::SpecSupport::Matchers::HaveHTMLAttribute`.
- `have_i18n_string` - check that a node's text has a string from your [I18n](/i18n)
configuration.  See `Brut::SpecSupport::Matchers::HaveI18nString`.

## Recommended Practices

### Instance variables (ivars) are fine.

Since `page_template` is a method of your class, it has access to your instance variables (ivars).  Feel free to
use them directly.  Only create `attr_reader` implementations if a subclass should be expected to override
something or you want something lazily evaluated.  Make them private. Your page's API is just the method `page_template`.

### Don't set ivars in `before_generate`

It's Ruby and you can do whatever you want, but your page class will be easier to understand and test if you set up necessary state in
your initializer.  Memoization is fine, but don't have your `before_generate` set up additional state if you can avoid it.  As we'll see
below, you won't need to use `before_generate` as a failsafe check on authorization.

### Leverage Keyword Injection

The list of available data for injection above will always be available to your page, with the exception of query string parameters.  The real power comes when you learn how to [inject your own data](/keyword-injection#injecting-custom-data) into the request context.

A great example of this is in the [recipe for keywords and auth](/recipes/page-keyword-auth), which results in a much simpler and less error-prone way to prevent unauthorized access to pages when compared to how you might do it in Rails.

### In Tests, It's Fine to Locate Elements Via CSS Selectors

Your page's job is to produce HTML.  To check if it's doing that, it makes sense to manipulate that HTML using standard, battle-tested
techniques like CSS selectors.  This creates consonance between your in-browser debugging and your test suite.

It also makes it much more obvious what's wrong if something is not where you expect it to be.

### That Said, Avoid Test-Specific Attributes or Classes

When you have a lot of `<div>` elements, it can be tempting to use attributes like `data-testid` on the elements you want to find in
your tests.  You can often avoid this if you use semantic markup and proper ARIA roles.  For example, a Flash message is likely
something you'd put in a `role="status"` or `role="alert"`, so you don't need `data-flash` or `class="flash"` in order to find it in a
test.

Custom Elements can also be helpful here, as that may be how you choose to manage your client-side behavior.

## Technical Notes

> [!IMPORTANT]
> Technical Notes are for deeper understanding and debugging. While we will try to keep them up-to-date with changes to Brut's
> internals, the source code is always more correct.

_Last Updated May 4, 2025_

### Page Internal API

A Page's core API is the method `handle!`, which can return an HTML-safe string, `URI`, or Rack response.
Developers should avoid overriding this method, as it also handles the logic related to calling `before_generate`
as well as the logic required to make layouts work.

This is why we recommend using `Brut::SpecSupport::ComponentSupport#generate_and_parse` or `Brut::SpecSupport::ComponentSupport#generate_result` in a tests.  *They* call `handle!`, thus ensuring your `before_generate` method will be called and that your page class will behave in a test the way it would in production.

### Layouts

Pages do not have to have a layout. You can override Phlex's `view_template` and produce HTML that will not be
wrapped in any Layout.  It may be a better idea to create a `BlankLayout` class to avoid this, but it's up to
you.

### Helpers in Templates

`Brut::FrontEnd::Page` is a subclass of `Brut::FrontEnd::Component`, so all your pages will have access to the helpers included there.  This is how, for example, `t` can be called to perform translations.

Note that Brut does *not* include `Brut::FrontEnd::Components` (pluralized).  You
can include that in `AppPage` to access Brut's builtin components as a Phlex kit.

### So You Don't Like Phlex?

Brut did initially use ERB, but the initial Brut-powered apps ended up having an all-too-common mess of HTML, Ruby, and angle brackets.  It really sucked.  Phlex seems pretty solid and is a very lightweight abstraction over HTML. It keeps everything in Ruby, but still maintains consonance to what you see in your browser.

Support for ERB, Slim, or HAML, is not planned ever.
