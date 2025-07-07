# Instrumentation and Observability

Brut has built-in support for OpenTelemetry, which is an open standard used by many observability vendors
to allow you to understand the behavior of your app in production.  Brut also includes a configuration for
the [otel-desktop-viewer](https://github.com/CtrlSpice/otel-desktop-viewer/), which allows you to see
instrumentation in development.

## Overview

### Why Instrument?

In production, you'll need to know what your app is doing and how well it's working.  Historically, logs
can provide this information in a roundabout way. Over the last many years, Application Performance
Monitoring (APM) vendors like New Relic and Data Dog allowed developers to see much richer detail about
how an app is working.

You could see, for example, the 95th percentil of your dashboard controller's performance, or the top 10
slowest SQL statements your app is executing.  OpenTelemetry attempts to unify the API used to communicate
this information from your app to your chosen vendor, and most vendors support it.

Instrumentation, then, is a way to record what your app is doing, how long its taking, and perhaps even
why it's doing what it's doing, down to a very specific level.  If properly configured, you could examine
the performance of the app for a particular user on a particular day.

### Setting up Instrumentation

Brut automatically sets up OpenTelemetry (OTel) tracing.  The primary interface you will use is
`Brut::Instrumentation::OpenTelemetry`, which is available via `Brut.container.instrumentation`.  We'll
discuss that in a moment.

To configure the specifics of where the traces will go, the OTel gem uses environment variables:

| Variable                             | Value                      | Purpose                                                                                                                                                         |
|--------------------------------------|----------------------------|-----------------------------------------------------------------------------------------------------------------------------------------------------------------|
| `OTEL_EXPORTER_OTLP_ENDPOINT`        | Depends on environment     | Where to send the tracers. This is provided by your vendor, but is `http://otel-desktop-viewer:4318` in development                                             |
| `OTEL_EXPORTER_OTLP_HEADERS`         | Depends on vendor          | Your vendor may ask you to set this. It often contains identifying information or API keys                                                                      |
| `OTEL_EXPORTER_OTLP_PROTOCOL`        | http/protobuf              | Your vendor may request a different protocol, but protobuf is common and supported by otel-desktop-viewer                                                       |
| `OTEL_LOG_LEVEL`                     | debug                      | Useful when setting everything up to understand why things aren't working if they aren't working                                                                |
| `OTEL_RUBY_BSP_START_THREAD_ON_BOOT` | false                      | Deals with esoteric issues with Puma. See [this GitHub issue](https://github.com/open-telemetry/opentelemetry-ruby/issues/462) for the details.
| `OTEL_SERVICE_NAME`                  | Your app's `id` from `App` | Identifiers your app's name to the vendor                                                                                                                       |
| `OTEL_TRACES_EXPORTER`               | otlp                       | Configures the class inside the OTel gem that will export the instrumentation to the vendor. If you omit this, Brut will log the instrumentation to the console |

When you created your Brut app, your `.env.development` and `.env.test` should have values for all these
environment variables that will send instrumentation to the otel-desktop-viewer that was also configured.

If you run your app using `bin/dev` and use the app for a bit, then go to `http://localhost:8000`, you
will see the otel-desktop-viewer UI and can browse the spans and traces sent by Brut.


### What is Instrumented By Default

Brut attempts to automatically instrument useful things so you don't have to do anything to start getting
data.  Brut will attempt to conform to standard semantics for HTTP requests and SQL statements.

Here is a non-exhaustive list of what Brut automatically instruments:

* How long each page or handler request takes, broken down by components.
* CLI execution time
* Time to rebuild the schema for tests
* Time to run tests
* Time to apply migrations
* Time spent inside a route hook
* The locale detected from the browser
* The layout class used when rendering a page
* If a requested path is owned by Brut or not
* Ignored parameters on all form submissions
* How long reloading takes in development
* CSP reporting results
* SQL Statements

> [!WARNING]
> `Sequel::Extensions::BrutInstrumentation` sets up telemetry for
> Sequel, and it does it in a relatively simplistic way.  The result
> is that *all* SQL statements are part of the telemetry, including
> the actual values inserted or used in `WHERE` clauses.
> While you should not be putting sensitive data into your database,
> be warned that this is happening. There are plans to improve this
> to be more flexible and reduce the chance of sensitive data
> being sent in traces.

### Adding Your Own Instrumentation

You can add instrumentation in a few ways:

* *Spans* record a block of code. They are shown as a sub-span if one is already in effect.  When you
create a span, that means it will be shown in the context of the HTTP request.
* *Attributes* can be added to the current span to provide more context about what is happening. For
example, the HTTP request method is an attribute of the span used for the HTTP request.  These attributes
allow for sophisticated querying in the vendor's UI.
* *Events* record things that happen and metadata about that thing. These are like log statements. They
are associated with the span you are in when you add the event.

These can all be added via `Brut.container.instrumentation`, which is a
`Brut::Instrumentation::OpenTelemetry` instance.

These methods are available:

* `span(name,**attributes,&block)` - Create a new span around the block yielded.
* `add_attributes(attributes)` - Add attributes to the current span. These will be prefixed with your
app's prefix so it's clear in the observability UI that they are for your app and not standard.
* `add_event(name,**attributes)` - Add an event with optional attributes for the current span.
* `record_exception(ex,attributes=nil)` - Record an exception that was caught.
* `record_and_reraise_exception!(ex,attributes=nil)` - Record an exception and raise it.

Suppose you want to instrument `RequireAuthBeforeHook` from the [hooks](/hooks) documentation. Although
the hook's `before` method is instrumented by Brut already, let's add some metadata to that span, and also
add a span around the login check.

```ruby {11-16,18,20,23-26}
# app/src/front_end/route_hooks/require_auth_before_hook.rb
class RequireAuthBeforeHook < Brut::FrontEnd::RouteHook
  def before(request_context:,session:,request:,env:)
    is_home_page       = request.path_info.match(/^\/?$/)
    is_auth_route      = request.path_info.match?(/^\/auth\//)
    is_brut_owned_path = env["brut.owned_path"]

    requires_login = !is_home_page  &&
                     !is_auth_route && 
                     !is_brut_owned_path
    Brut.container.instrumentation.add_attributes(
      requires_login:,
      is_home_page:,
      is_auth_route:,
      is_brut_owned_path:
    )

    Brut.container.instrumentation.span("login-check") do |span|
      if session.logged_in?
        span.add_attributes(logged_in: true)
        request_context[:authenticated_account] = session.authenticated_account
        requires_login = false
      else
        span.add_attributes(logged_in: false)
      end
    end

    if requires_login
      redirect_to(Auth::LoginPage)
    else
      continue
    end

  end
end
```

Now, for every request someone makes to our app, we will see a span for the `RequireAuthBeforeHook`, and
inside that span, we'll see the attributes we added as well as a sub-span representing the login check
(which itself will have an attribute about the user's logged-in status).

### Client-Side Observability


The class `Brut::FrontEnd::Handlers::InstrumentationHandler` is set up to receive information from the
client-side to provide insights about client-side behavior as part of a server-side request.  Brut
attempts to join up any client-side instrumentation to the request that served it.

It does this via the `Brut::FrontEnd::Components::Traceparent` component, which is included in your default layout when you created your Brut app.  This creates a `<meta>` tag containing standardized information used to
connect the client-side behavior to the server-side request.

The Brut custom element `<brut-tracing>` uses this information, along with statistics from the browser, to
send a custom payload back to Brut at the route `/__brut/instrumentation`, which is handled by the
aforementioned `InstrumentationHandler`.

You should then see client-side tracing information as a sub-span of your HTTP request.  The information available depends on the browser, and some browsers don't send much. Also keep in mind that clock drift is real and while client-side timings are accurate, the timestamps will not be.

## Testing

Generally you don't want to test instrumentation unless it's highly complex and critical to the app's
ability to be maintained.  Ideally, your end-to-end tests will cover all the instrumentation code you
write so you can be sure that none of that causes a problem.

## Recommended Practices

Entire books and conferences exist on how to properly instrument your app.  Our suggestion is to take what
you have by default and add additional instrumentation only to solve specific problems or identify
specific issues.

## Technical Notes

> [!IMPORTANT]
> Technical Notes are for deeper understanding and debugging. While we will try to keep them up-to-date with changes to Brut's
> internals, the source code is always more correct.

_Last Updated June 12, 2025_


Brut does not have plans to support non-OTel instrumentation, nor does it have plans to provide hooks to use proprietary formats.

The client-side portion of this is highly customized.  The Otel open source code for the client side is
massive and hugely complex, so Brut decided to try to produce something simple and straightforward as a
start. This can and will evolve over time.
