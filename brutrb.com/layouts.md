# Layouts

Brut supports *layouts*, which are a way to centralizing common HTML amongst many
different pages.  Conceptually, they are the same as a Rails layout.  Technically, they are a Phlex component designed to render a page from a `yield` block.

## Overview

Your app should include `app/src/front_end/layouts/default_layout.rb`. The name
"default" is special, in that all pages will use this layout by default.

Since a layout is a Phlex component, its HTML is generated from `view_template`, and
it is expected to have exactly one `yield`, where the page's content will be
inserted.

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

### Maintaining Layouts

You are free to manage this how you like, however a few components inside the
`<head>` and `<body>` that are important to keep:

* `Brut::FrontEnd::Components::PageIdentifier` includes a `<meta>` tag with the page's name in it, which is handy for managing your end-to-end tests.
* `Brut::FrontEnd::Components::I18nTranslations` includes translatsion for common client-side constraint violations.  See [Forms](/forms), [I18n](/i18n), and [JavaScript](/javascript) for more details on how this is used.
* `Brut::FrontEnd::Components::Traceparent` ensures that the OpenTelemetry *traceparent* is available so when client-side telemetry is reported back to the server, it can be connected to the request that initiated it.
* The `<brut-tracing>` element collects the client-side telemetry and sends it back
to the server.

### Creating Alternate Layouts

The way each page knows to use `DefaultLayout` is due to the `layout` method of
`Brut::FrontEnd::Page`, which returns `"default"`.  The return value of `layout` is
used to figure out the name of the layout class.

You can set up your own by overriding `layout`:

```ruby
class MyOtherPage < AppPage
  def layout = "other_design"

  # ...

end
```

Brut will expect the class `OtherDesignLayout` to exist and provide HTML.  Based on
Zeitwerk's conventions, that class should be in
`app/src/front_end/layouts/other_design_layout.rb`.

### No Layout

If you don't want a layout, you are encouraged to creat a blank layout, for example:

```ruby
class BlankLayout < Brut::FrontEnd::Layout
  def view_template
    yield
  end
end

# use like so:

def layout = "blank"
```

## Testing

You generally don't test a layout, aside from end-to-end tests.  If your layout
needs complex logic, you are encouraged to extract that to a
[component](/components) and test that instead.

## Recommended Practices

Keep your layouts as simple as you can.



## Technical Notes

> [!IMPORTANT]
> Technical Notes are for deeper understanding and debugging. While we will try to keep them up-to-date with changes to Brut's
> internals, the source code is always more correct.

_Last Updated July 1, 2025_

Layouts work due to the implementation of the method `view_template` in `Brut::FrontEnd::Page`. This is why a page class must provide `page_template` instead.

While you could override `view_template` in your page to provide a "blank layout",
this is discouraged, as the use of `view_template` should be considered a
private implementation detail.


