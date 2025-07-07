# Layouts

Brut supports *layouts*, which are a way to centralizing common HTML amongst many
different pages.  Conceptually, they are the same as a Rails layout.  Technically, they are a Phlex component designed to render a page from a `yield` block.

## Overview

Your app should include `app/src/front_end/layouts/default_layout.rb`. The name
"default" isn't special, it's just what the `layout` method from
`Brut::FrontEnd::Page` returns.

A layout is a Phlex component that's expected to have a single call to `yield` in
its `view_template` method.

Here is the `DefaultLayout` provided to new Brut apps:

```ruby {33}
class DefaultLayout < Brut::FrontEnd::Layout
  include Brut::FrontEnd::Components

  def initialize(page_name:)
    @page_name = page_name
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
        PageIdentifier(@page_name)
        I18nTranslations("cv.fe")
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
        main class: @page_name do
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

See [creating alternate layouts](/recipes/alternate-layouts) and [blank
layouts](/recipes/blank-layouts) for customization options.

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

_Last Updated July 1, 2025_

Layouts work due to the implementation of the method `view_template` in `Brut::FrontEnd::Page`. This is why a page class must provide `page_template` instead.

While you could override `view_template` in your page to provide a "blank layout",
this is discouraged, as the use of `view_template` should be considered a
private implementation detail.


