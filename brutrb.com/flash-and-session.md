# Flash and Session

Brut sessions are stored in cookies, encrypted to prevent tampering.  The *flash*, which is a way to temporarily
store small bits of information between page loads, is encoded in the session.

## Overview

Unlike Rails, the session and flash are presented to you as objects, not Hashes.  By declaring the `session:`
parameter on an initializer, you'll be given the current session for the request as an `AppSession`, which
inherits from `Brut::FrontEnd::Session`.  Similarly, declaring `flash:`, you'll get a `Brut::FrontEnd::Flash`.

The idea is to use Ruby's type system to describe what data is in the session and flash.

### Session

Brut's session is somewhat richer than you might get from other frameworks.  In particular, the session can
provide you:

* The current `Brut::I18n::HTTPAcceptLanguage`, which is the visitor's locale. See [I18n](/i18n) for how this
works and how to use this value.
* The timezone as provided by the browser.
* An explicitly-set timezone that may or may not be what the browser provided.  See [Space-Time Continuum](/space-time-continuum) for more details.

The session also handles serializing the flash to and from the browser's cookies and can store any arbitrary data
you like via `[]`.  You are encouraged to add methods to your app's `AppSession` to make it explicit what you are
storing.

Let's  see the [route hook](/hooks) from  the [pages](/pages) section again.

> [!CAUTION]
> This hook is not production-ready. It lacks certain error-handling situations and
> makes an assumption about how the session is managed. It's for demonstration only.
> The [route hooks](/hooks) section has a more
> appropriate example.

```ruby
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

When this hook executes, `session` will be an `AppSession`, serialized from the browser's cookies.  Here's what
that class might look like:

```ruby
# app/src/front_end/support/app_session.rb
class AppSession < Brut::FrontEnd::Session
  def login!(current_user:)
    self[:current_user_id] = current_user.id
  end

  def logout!
    self[:current_user_id] = nil
  end

  def logged_in?
    !!self.current_user_id
  end

  def current_user_id = self[:current_user_id]
end
```

The session is a rich object and not just a thin wrapper over a Hash.  You could even have the session perform
the lookup in the database:

```ruby {11,14-16}
# app/src/front_end/support/app_session.rb
class AppSession < Brut::FrontEnd::Session
  def login!(current_user:)
    self[:current_user_id] = current_user.id
  end
  def logout!
    self[:current_user_id] = nil
  end

  def logged_in?
    !!self.current_user
  end

  def current_user
    DB::User.find(id: self[:current_user_id])
  end
end
```

Now, the hook could call `current_user`:

```ruby {3-5}
class RequireAuthBeforeHook < Brut::FrontEnd::RouteHook
  def before(request_context:,session:)
    if session.logged_in?
      request_context[:current_user] = session.current_user
    end
  end
end
```

Let's see `LoginHandler` from the [handlers](/handlers) section, to see how to save the current user.  Given what
we've learned, the declaration of the `session:` parameter to the initializer means the relevant instance of
`AppSession` will be passed in.

```ruby {20}
# app/src/front_end/handlers/login_handler.rb
class LoginHandler < AppHandler
  def initialize(form:, session:)
    @form    = form
    @session = session
  end

  def handle
    if !@form.constraint_violations?
      authorized_user = AuthorizedUser.login(
        email: form.email,
        password: form.password
      )
      if authorized_user.nil?
        @form.server_side_constraint_violation(
          input_name: :email,
          key: :login_not_found
        )
      else
        session.login!(current_user: authorized_user.user)
      end
    end
    if @form.constraint_violations?
      LoginPage.new(form: @form)
    else
      redirect_to(DashboardPage.routing)
    end
  end
end
```

Brut will handle saving the updated values in the response so when, in this case, the `DashboardPage` is
rendered, it can see which user is logged in.

### Flash

By default, your app will use Brut's flash class, `Brut::FrontEnd::Flash`.  This is because you typically don't
need to enhance the flash.  Brut's flash has an "alert" and "notice", and you can use them however you see fit. You can also set arbitrary messages in the flash via `[]`.

The contents of the flash only survive one request, so anything you set will be available in that session's next
request, but not after that.

Note that the flash's alert and notice are intended to be I18n keys.  You don't have to use them this way, but it
is encouraged.  If you pass an array into `alert=` or `notice=`, the elements will be joined to form an I18n key.

You can create your own subclass if you need a richer flash class than the one Brut provides.

First, create your class. It can be anywhere, but we recommend `app/src/front_end/support/app_flash.rb`:

```ruby
# app/src/front_end/support/app_flash.rb
class AppFlash < Brut::FrontEnd::Flash
  # For example
  def debug=(debug)
    self[:debug] = debug
  end
  def debug  = self[:debug]
  def debug? = !!self.debug
end
```

Then, in your `App`, located in `app/src/app.rb`, use `Brut.container.override` to change the class used for the
flash:

```ruby
class App < Brut::Framework::App
  # ...
  def initialize
    Brut.container.override(
      "flash_class",
      AppFlash
    )
  end

  # ...
end
```

Brut's configuration system is discussed in more detail in [Configuration](/configuration).

## Testing

Testing your session or flash classes may not be super valuable, however they are normal Ruby objects so you can
test them in a conventional way.  Both classes treat their internals as a Hash, so you can implement and assert
via the `[]` and `[]=` methods.

## Recommended Practices

While you can use both the flash and the session has a hash of whatever, your are encouraged to avoid this in
your production code.  Create well-defined attributes or methods to manipulate these objects using the language
of your domain.


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

