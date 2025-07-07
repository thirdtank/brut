# Custom Flash Class

If you want to have a more sophisticated [Flash](/flash-and-session), you can do
this by overriding Brut's [configuration](/configuration).

## Recipe

First, create your new class in `app/support/app_flash.rb`. You can implement your
new methods using `[]` and `[]=`.

```ruby
class AppFlash < Brut::FrontEnd::Flash
  def debug  =   self[:debug]
  def debug? = !!self.debug

  def debug=(debug_message)
    self[:debug] = debug_message
  end
end
```

Now, in `app/src/app.rb`'s initializer, use `Brut.container.override`:

```ruby {6}
class App < Brut::Framework::App
  def initialize

    # ...

    Brut.container.override("flash_class",AppFlash)
  end
end
```

Now, any time you inject `flash:` into a component, it'll be an instance of
`AppFlash`:

```ruby
class HomePage < AppPage
  def initialize(flash:)
    @flash = flash
  end

  def page_template
    h1 { "Welcome!" }
    if @flash.debug?
      aside { @flash.debug }
    end
  end
end
```
