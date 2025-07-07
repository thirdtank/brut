# Flash and Session

Brut sessions are stored in cookies, encrypted to prevent tampering.  The *flash*, which is a way to temporarily store small bits of information between page loads, is encoded in the session.

## Overview

Unlike Rails, the session and flash are presented to you as objects, not Hashes of Whatever.  By declaring the `session:`
parameter on an initializer, you'll be given the current session for the request as an `AppSession`, which inherits from `Brut::FrontEnd::Session`.  Similarly, declaring `flash:`, you'll get a `Brut::FrontEnd::Flash`.

The idea is to use Ruby's type system to describe what data is in the session and flash.

### Session

Brut's session is somewhat richer than you might get from other frameworks.  In particular, the session can provide you:

* The current `Brut::I18n::HTTPAcceptLanguage`, which is the visitor's locale. See [I18n](/i18n) for how this
works and how to use this value.
* The timezone as provided by the browser.
* An explicitly-set timezone that may or may not be what the browser provided.  See [Space-Time Continuum](/space-time-continuum) for more details.

To access the session, declare it as a keyword argument to your page, handler, or
global component's intitializer:

```ruby
class HomePage < AppPage
  def initialize(session:)
    @session = session
  end
end
```

When you create your Brut app, your `AppSession` won't have anything in it, although
it's a `Brut::FrontEnd::Session`, so you can certainly use `[]` and `[]=` on it.
However, you are encouraged to declare methods that describe precisely what is in
the session.

Let's say the currently logged-in visitor is available in the session.  Your
`HomePage` could look like so:

```ruby
class HomePage < AppPage
  def initialize(session:)
    @session = session
  end

  def view_template
    h1 do
      if @session.current_visitor
        "Hello #{@session.current_visitor.name}"
      else
        "Hi!"
      end
    end
  end
end
```

Let's suppose a `LoginHandler` exists, that can set a value for `current_visitor`:

```ruby
class LoginHandler < AppHandler
  def initialize(form:, session:)
    @form    = form
    @session = session
  end

  def handle
    visitor = Login.from_form(form:) # assume this exists
    if visitor
      @sesion.login!(visitor:)
    else
      # ...
    end
  end
end
```

`AppSession` would need to look like so:

```ruby
class AppSession < Brut::FrontEnd::Session
  def login!(visitor:)
    self[:current_visitor_id] = visitor.id
  end

  def current_visitor
    DB::Visitor.find(id: self[:current_visitor_id])
  end
end
```

Brut encourages your session to be a rich object.  You can declare any methods you
like:

```ruby
class AppSession < Brut::FrontEnd::Session
  def logged_in? = !!self.current_visitor
end
```

> [!NOTE]
> When dealing with auth, you can leverage
> keyword injection beyond injecting the session.  This is
> discussed in [the auth recipe](/recipes/authentication.md)

### Flash

To access the flash, declare it as a keyword argument to your page, handler, or
global component's intitializer:

```ruby {2,4}
class DeleteWidgetByIdHandler < AppHandler
  def initialize(widget_id:, flash:)
    @widget_id = widget_id
    @flash     = flash
  end
end
```

By default, the flash will be a `Brut::FrontEnd::Flash`.  While you can set your own
class, this is less commonly needed, so Brut doesn't provide one by default.  Like
the session, you can use `[]`, but are discouraged from this to avoid Hashes of
Whatever littering your code.

The default flash provides a `notice` attribute and an `alert` attribute. Their
values only survive one request, so anything you set will be available in that session's next request, but not after that.

The values are expected to be I18n keys:

```ruby {5,8}
  def handle
    widget = DB::Widget.find!(id: @widget_id)
    if widget.can_delete?
      widget.delete
      @flash.notice = :widget_deleted
      redirect_to(WidgetsPage)
    else
      @flash.alert = :widget_cannot_be_deleted
      WidgetsPage.new
    end
  end
end
```

This is only enforced by convention, but you should stick to one convention since
you will likely create a [global component](/components) for the flash:

```ruby {17}
class FlashComponent < AppComponent
  def initialize(flash:)
    if flash.notice?
      @message_key = flash.notice
      @role = :info
    elsif flash.alert?
      @message_key = flash.alert
      @role = :alert
    end
  end

  def any_message? = !@message_key.nil?

  def view_template
    if any_message?
      div(role: @role) do
        t([ :flash, @message_key ])
      end
    end
  end
end
```

See [using your own Flash class](/recipes/custom-flash) to see how to enhance Brut's
flash with your own logic.

## Testing

Testing your session or flash classes may not be super valuable, however they are normal Ruby objects so you can
test them in a conventional way. Although you are discouraged from using `[]` and
`[]=` as the public API of your session or flash, they can be useful for assertions
or test setup.

## Recommended Practices

Do not treat the session or flash as a Hash of Whatever.  Isolate all magic keys to
the class and provide a rich API.  It doesn't take that much effort and will make
your app way easier to manage.

## Technical Notes

> [!IMPORTANT]
> Technical Notes are for deeper understanding and debugging. While we will try to keep them up-to-date with changes to Brut's
> internals, the source code is always more correct.

_Last Updated May 7, 2025_

The session is based on [`Rack::Session`](https://github.com/rack/rack-session), which is configured explicitly
in your app's `config.ru`. (TBD: WHY?)

The session object itself is created on demand for any route hook that needs it.
Since `Brut::FrontEnd::RouteHooks::SetupRequestContext` requires the session, the
`Brut::FrontEnd::RequestContext` is created here and given the session (and flash) that is used for subsequent
hooks and HTML generation.

The flash is created largely on-demand and is a special hash serialized into the session.  The hash contains the
current age of the flash and then all the messages.  This format could use improvement and may change.
`Brut::FrontEnd::RouteHooks::AgeFlash` is a route hook that handles increasing the age of the flash, however the
flash itself controls when to "age out" messages.  None of this is currently configurable.

