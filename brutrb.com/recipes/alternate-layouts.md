# Alternate Layouts

To create an alternate layout, your page can override `layout` to return a string.
That string will be camel-cased and preped to `Layout` to form a class that is
expected to exist and provide the layout. That class must extend
`Brut::FrontEnd::Layout`.

```ruby
class MyOtherPage < AppPage
  def layout = "other_design"

  # ...

end

class OtherDesignLayout < Brut::FrontEnd::Layout
  def view_template
    doctype
    html do
      head do
        link(rel: "preload", as: "style", href: asset_path("/css/other-styles.css"))
        link(rel: "stylesheet",           href: asset_path("/css/other-styles.css"))
        script(defer: true, src: asset_path("/js/app.js"))
      end
      body do
        yield
      end
    end
  end
end
```

