# Pages

The core abstraction of Brut is the core concept of the web: the web page.

A web page is fetched by the browser using an HTTP `GET` request to a URL. When that happens, Brut instantiates an object of a *page class* and uses its `page_template` method to generate its HTML (using calls to Phlex's API).

## Overview

You can create everything you need for a page by using `bin/scaffold`:

```shell
> bin/scaffold page /new-widgets
```

You can use `--dry-run` to see what it will do:

```shell
> bin/scaffold --dry-run /new-widgets
bin/scaffold --dry-run page /new-widgets
[ bin/scaffold ] app/src/app.rb
[ bin/scaffold ] will contain:

page "/new-widgets"

[ bin/scaffold ] app/src/front_end/pages/new_widgets_page.rb
[ bin/scaffold ] will contain:

class NewWidgetsPage < AppPage
  def initialize # add needed arguments here
  end

  def page_template
    h1 { "Your page is ready" }
  end
end

[ bin/scaffold ] specs/front_end/pages/new_widgets_page.spec.rb
[ bin/scaffold ] will contain:

require "spec_helper"

RSpec.describe NewWidgetsPage do
  it "should have tests" do
    expect(true).to eq(false)
  end
end

[ bin/scaffold ] app/config/i18n/en/2_app.rb
[ bin/scaffold ] will contain:

       "NewWidgetsPage": {
         title: "New widgets page",
       },

[ bin/scaffold ] Page source is in        app/src/front_end/pages/new_widgets_page.rb
[ bin/scaffold ] Page HTML template is in app/src/front_end/pages/new_widgets_page.html.erb
[ bin/scaffold ] Page test is in          specs/front_end/pages/new_widgets_page.spec.rb
[ bin/scaffold ] Added title to           app/config/i18n/en/2_app.rb
[ bin/scaffold ] Added route to           app/src/app.rb
```

You can, of course, edit `app.rb` and create the classes yourself.

> [!WARNING]
> Adding a `page` route without the corresponding class may not always
> work, since Brut may try to load the class.  Brut does its best
> to avoid problems, but you should create your route and classes
> all at once

> [!IMPORTANT]
> Brut cannot currently reload new routes, so you must
> restart your dev server when you modify or add routes.

### Creating a Page

Page classes are expected to be in `app/src/front_end/pages`, named conventionally the way Zeitwerk would expect.  For example, `Admin::WidgetsByIdPage` would be expected in `app/src/front_end/pages/admin/widgets_by_id_page.rb`.

A page class must be a subclass of `Brut::FrontEnd::Page`, however in practice it will be a subclass of `AppPage` in your app, which is a subclass of `Brut::FrontEnd::Page`.  All Brut components have an app-specific base class to allow sharing of logic, if needed.

Brut will create the instance of the page class, passing in the keyword
arguments the initializer specifies (see [Keyword Injection](/keyword-injection)). In particular, any placeholders in the route will be passed-in to the initializer. This is why those placeholders must be valid Ruby keyword argument names.

For example, `Admin::WidgetsByIdPage` and its template might look like so:

```ruby 
# pages/admin/widgets_by_id_page.rb
class Admin::WidgetsByIdPage < AppPage
  def initialize(id:)
    @widget = DB::Widget.find!(id:)
  end

  private attr_reader :widget

  def page_template
    h1 { widget.name }
    h2 { widget.status }
  end
end
```

Note that `Admin::WidgetsByIdPage` is a normal Ruby class, so you could implement `#widget` as a method, and lazy-load the widget:

```ruby {13}
class Admin::WidgetsByIdPage < AppPage
  def initialize(id:)
    @widget_id = id
  end

  def page_template
    h1 { widget.name }
    h2 { widget.status }
  end

private

  def widget = DB::Widget.find!(id: @widget_id)

end
```

A page's initializer can also accept other parameters, provided by Brut.

### Arguments Available to Initializer

Brut's [keyword injection](/keyword-injection) is used to create the instance of your page.  You can have Brut inject what you need by
specifying keyword arguments.

| Value | Type | Description |
|-------|------|-------------|
`session:` | `Brut::FrontEnd::Session` (or your app's subclass) | The current session, even if it's empty. See [Flash and Session](/flash-and-session)|
`flash:` | `Brut::FrontEnd::Flash` (or your app's subclass) | The current flash, even if it's empty. See [Flash and Session](/flash-and-session) |
`xhr:` | `true` or `false` | true if this was an Ajax request|
`csrf_token:` | `String`| The current CSRF token. |
`clock:` | `Clock` | Used when you need to access the current date and time, potentially accounting for time zones.   See [Space/Time Continuum](/space-time-continuum)|
`http_*` | `String` or `nil` | Any parameter that starts with `http_` is assumed to be for an HTTP header. For example, `http_accept_language` would be given the value for the "Accept-Language" header. See [HTTP Headers](/keyword-injection#http-headers) |
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
> Keyword arguments for query string parameters **must** have default values or Brut will be unable to instantiate your page class
> when they are omitted.

> [!NOTE]
> Omitting a default for an HTTP header is OK, but you should know what the behavior is. See [the HTTP Headers
> section](/keyword-injection#http-headers) for details.

### Hooks

Occasionally, you want to prevent a page from rendering after the visitor has been routed to it.  A common
reason for this could be a lack of authorization by that visitor to view the page.

`before_generate` achieves this. If your page class implements it, it will be called after the page is
initialized, but before the template creationg process starts.  Depending on what `before_generate`
returns, the visitor may be redirected, an error could be sent, or HTML generation may proceed as normal.

The return value of `before_generate` determines what will happen:

* `URI` - the visitor will be redirected to the given URI.  Instead of creating a `URI`, you may use the method `redirect_to`, which
accepts a page and its parameters.
* `Brut::FrontEnd::HttpStatus` - the page will not be rendered and this status will be returned. You may use `http_status` to create
an `HttpStatus` from a number.
* `Brut::FrontEnd::GenericResponse` - a typed wrapper around the standard Rack response.
* Anything else - page rendering will proceed as usual.

## Testing

See [Unit Testing](/unit-tests) for some basic assumptions and configuration available for all Brut unit tests.

Since pages are Plain Ole Ruby Objects, you could test them using conventional means.  However, since the ultimate behavior of a
page is to produce HTML based on its template, it's recommended that your page tests generate HTML and you make assertions about the page's behavior by examining that HTML.

Brut provides convenience methods for this, based on Nokogiri.  With them, you should be able to access elements of your page using
the same sorts of CSS selectors you'd use with `document.querySelector` to debug your app in a browser.

### `generate_and_parse` Parses the Generated HTML

Brut uses RSpec, so when a page test is detected, Brut will include `Brut::SpecSupport::ComponentSupport`, which provides useful methods and includes other modules you'll need to make testing more straightforward.

The main method you'll use is `generate_and_parse`, which accepts an instance of your page and returns a
`Brut::SpecSupport::EnhancedNode`, which is a delegate to a Nokogiri node.

Below, we use the method `e!`, which is provided by `EnhancedNode`. This works just like Nokogiri's `css`, except
that requires exactly one element to match the selector. If not, the test fails.  This allows a more compact test
when you know there should only be one element matching the selector you've provided.

```ruby
RSpec.describe CompanyByCompanyId::LocationsByLocationIdPage do
  describe "render" do
    it "shows the company name and location address" do
      company  = create(:company)  # You must implement
      location = create(:location) # You must implement

      page = described_class.new(company_id: company.id.to_s,
                                 location_id: location.id.to_s)

      parsed_html = generate_and_parse(page)

      h1 = parsed_html.e!("h1")
      h2 = parsed_html.e!("h2")

      expect(h1.text).to include(company.name)
      expect(h2.text).to include(location.address)
    end
  end
end
```

`e` (without a bang/`!`) is also provided, which will allow zero or one elements to match the selector (i.e. it only fails if there is more than one match).  `e` and `e!` are key methods that allow the use of CSS selectors to be usable in your tests.

See `Brut::SpecSupport::ClockSupport`, `Brut::SpecSupport::FlashSupport`, and `Brut::SpecSupport::SessionSupport` for additional methods you can use to make it easier to work with clocks, flashes, and sessions, respectively.

### `generate_result` Tests `before_generate`

If your page uses `before_generate`, when you call `generate_and_parse`, it will fail unless the page generated
HTML.  In those cases, you can use `generate_result`, which will return what `before_generate` returned, unless
it returned `nil`, in which case it will return the unparsed HTML.

```ruby {4,10,12}
RSpec.describe CompanyByCompanyId::LocationsByLocationIdPage do
  describe "render" do
    it "redirects back to the home page for expired companies" do
      company  = create(:company, :expired)  # You must implement
      location = create(:location) # You must implement

      page = described_class.new(company_id: company.id.to_s,
                                 location_id: location.id.to_s)

      result = generate_result(page)

      expect(result).to have_redirected_to(HomePage)

    end
  end
end
```

`have_redirected_to` is a matcher provided by Brut. `have_returned_http_status` is also available to assert that
`before_generate` returned an HTTP status.  The reason to use these matchers and `generate_result` instead of
calling `before_generate` directly is that you want to use the page in a test the way it's used in your app.  You
will also get higher-quality test failure messages.

## Recommended Practices

You can build your pages however you like, but here are some tips that will make your app more sustainable and
easier to work with.

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

Let's take a common example of a page that require that a visitor be logged in.  While your app will have logic to avoid routing a logged-out visitor to any of those pages, it may seem like a good practice to add a failsafe check inside the logic of the page requiring login. This is very common in Rails and might look like so:

```ruby{2}
class WidgetsController < ApplicationController
  before_action :require_login!

  # ...
end
```

`before_action` is the failsafe - in case someone hacks a URL to find this page, or there is a bug in your app where unauthorized visitors are sent to this page, the `before_action` prevents the page from working.

In Brut, you could mimic this behavior using `before_generate`, however this isn't necessary.  Instead, you can take advantage of keyword injection.

Consider this implementation of `WidgetsByIdPage`:

```ruby
class WidgetsByIdPage < AppPage
  def initialize(id:, current_user:)
    # ...
  end
end
```

`id:` is injected because it is a route placeholder.  `current_user:` however, is completely custom to our app.  We can arrange to
have it injected.  We'll create a [Route Hook](/hooks) to do this.

> [!CAUTION]
> This hook is not production-ready. It lacks certain error-handling code and
> makes an assumption about how the session is managed. It's for demonstration only.
> The [route hooks](/hooks) section has a more
> appropriate example.

```ruby{6}
class RequireAuthBeforeHook < Brut::FrontEnd::RouteHook
  def before(request_context:,session:)
    if session.current_user_id
      user = DB::User.find(id: session.current_user_id)
      if user
        request_context[:current_user] = user
      end
    end
  end
end
```

Before any route is handled, this before hook is run and passed the `Brut::FrontEnd::RequestContext`.  This is where all the
injectible values live.  `request_context[:current_user] = user` makes `user` available to be injected into a page or handler.

What this means is that when a visitor is not logged in, there will be no injectible value for `:current_user`.  Brut will not be able
to instantiate `WidgetsByIdPage`, and an error is generated.  It is literally impossible to route a logged-out visitor to that page.

In practice, this means that any page that requires a logged-in visitor will specify the `current_user:` keyword argument, and **not provide a default value**.  You are still required to make sure no one routes a logged-out visitor to a page requiring authentication, but now you don't have to remember to add logic to each page that requires login—you bake it into the page class' type.

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

`Brut::FrontEnd::Page` is a subclass of `Brut::FrontEnd::Component`, so all your pages will have access to the helpers included there.  This is how, for example, `t` can be called to perform translations, or `time_tag` can be used to create a `<time>` HTML element.

If you wish to add helpers to be used in more than one page, you can either add the method to a common base class like `AppPage`, or create a module and `include` it.

### So You Don't Like Phlex?

Brut did initially use ERB, but the initial Brut-powered apps ended up having an all-too-common mess of HTML, Ruby, and angle brackets.  It really sucked.  Phlex seems pretty solid and is a very lightweight abstraction over HTML. It keeps everything in Ruby, but still maintains consonance to what you see in your browser.

Support for ERB, Slim, or HAML, is not planned ever.
