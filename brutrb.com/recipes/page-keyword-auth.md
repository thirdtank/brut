# Keyword Auth

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
