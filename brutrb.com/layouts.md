# Layouts

Brut supports *layouts*, which are a way to centralizing common HTML amongst many
different pages.  Conceptually, they are the same as a Rails layout.  Technically, they are a Phlex component designed to render a page from a `yield` block.

## Overview

Your app should include `app/src/front_end/layouts/default_layout.rb`. The name
"default" isn't special, it's just what the `layout` method from
`Brut::FrontEnd::Page` returns.

A layout is a Phlex component that's expected to have a single call to `yield` in
its `view_template` method.

### Default Layout and Common Layout Needs

Here is the `DefaultLayout` provided to new Brut apps:

```ruby {33}
class DefaultLayout < Brut::FrontEnd::Layout
  include Brut::FrontEnd::Components

  def initialize(page:)
    @page = page
  end

  def view_template
    doctype
    html(lang: "en") do
      head do
        meta(charset: "utf-8")
        meta(content: "width=device-width,initial-scale=1", name:"viewport")
        meta(content: "website", property:"og:type")
        link(rel: "manifest",  href: "/static/manifest.json")
        link(rel: "preload", as: "style", href: asset_path("/css/styles.css"))
        link(rel: "stylesheet",           href: asset_path("/css/styles.css"))
        script(defer: true, src: asset_path("/js/app.js"))
        title { app_name }
        PageIdentifier(page)
        I18nTranslations("cv.cs")
        I18nTranslations("cv.this_field")
        Traceparent()
        render(
          Brut::FrontEnd::RequestContext.inject(
            Brut::FrontEnd::Components::LocaleDetection
          )
        )
      end
      body do
        brut_tracing url: "/__brut/instrumentation", show_warnings: true
        main class: page.page_name do
          yield
        end
      end
    end
  end
end
```

You will likely want to customize what's in your layout, but a few components
included by default are important for other features of Brut:

| Component | Purpose
|---|---|
| `Brut::FrontEnd::Components::PageIdentifier` | Creates a `<meta>` tag with the page's name in it, which is handy for managing your end-to-end tests. |
| `Brut::FrontEnd::Components::I18nTranslations` | Includes translatsion for common client-side constraint violations.  These are used by `<brut-cv-messages>` and `,brut-cv>`. See [Forms](/forms), [I18n](/i18n), and [JavaScript](/javascript) for more details |
| `Brut::FrontEnd::Components::Traceparent` | Includes the OpenTelemetry *traceparent* on the page so that client-side telemetry is reported back to the server.  See `<brut-tracing>` and [observability](/instrumentation) |
| `<brut-tracing>` / `brut_tracing` | Custom element that collects the client-side telemetry and sends it back to the server. See [observability](/instrumentation) |

### Adding Logic/Dynamic Behavior to Layouts

Often, your pages will need to make slight tweaks to the layout that don't apply to all pages. For example, you may wish for a certain page to refresh on a schedule and you want to do that with a [meta refresh](https://en.wikipedia.org/wiki/Meta_refresh), which must appear in the `<head>` of the page.

Unlike Rails, which uses named blocks to render optional or dynamic content, Brut allows you to use methods and normal Ruby-based flow logic.  Since your layouts have access to the page they are laying out, you can use your pages' APIs to do whatever it is you need.

Taking the meta refresh example, suppose your `AppPage` defines a method, `auto_refresh_seconds` that, if non-`nil` means your page should automatically reload itself after that many seconds.  By default, you don't refresh, so it returns `nil`:

```ruby
class AppPage < Brut::FrontEnd::page

  # ...

  def auto_refresh_seconds = nil

  # ...
end
```

Your layout can refrence this API, since it's just a method on a class:

```ruby
class DefaultLayout < Brut::FrontEnd::Layout

  # ...

  def view_template
    doctype
    html(lang: "en") do
      head do
        if page.auto_refresh_seconds
          meta(http_equiv: safe("refresh"), content: page.auto_refresh_seconds)
        end

        # ...
  end
  # ...
end
```

Since your pages are a class hierarchy, you can override `auto_refresh_seconds` in any page, and that page will automatically refresh itself:

```ruby
class DashboardPage < AppPage

  def auto_refresh_seconds = 60 * 60

  # ...

end
```

### Alternate Layouts

If you used `mkbrut`, you should have access to a `BlankLayout` that is useful for allowing a page to respond to Ajax requests:

```ruby
class SomePage < AppPage
  def layout = "blank"
end
```

See [creating alternate layouts](/recipes/alternate-layouts) for more information on creating alternate layouts based on your needs.

## Testing

You generally don't test a layout, aside from end-to-end tests.  If your layout
needs complex logic, you are encouraged to extract that to a
[component](/components) and test that instead.

## Recommended Practices

Layouts can use components, just keep in mind that any data a component needs must
be passed to its initializer. Since the layout doesn't have access to the page, this
implies that components used in your layout must either not require dynamic data or
be [global components](/components#global-components)

## Technical Notes

> [!IMPORTANT]
> Technical Notes are for deeper understanding and debugging. While we will try to keep them up-to-date with changes to Brut's
> internals, the source code is always more correct.

_Last Updated Sep 9, 2025_

Layouts work due to the implementation of the method `view_template` in `Brut::FrontEnd::Page`. This is why a page class must provide `page_template` instead.

