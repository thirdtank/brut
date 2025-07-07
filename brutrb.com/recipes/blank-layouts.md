# Blank or No Layout

If you don't want a layout, you are encouraged to create a blank layout, for example:

```ruby
class BlankLayout < Brut::FrontEnd::Layout
  def view_template
    yield
  end
end

# use like so:

class NakedPage < AppPage
  def layout = "blank"

  def page_template
    # ...
  end
end
```

