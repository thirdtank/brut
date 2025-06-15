# Route Hooks

Route hooks are similar to [Middleware](/middleware), but have a richer API and aren't as low-level. Route
hooks can happen before a page or handler is called, or after.

## Overview

We've seen examples thusfar of using a route hook to place the authenticated user or account into the
request context for later injection into pages or handlers. Brut uses route hooks to locale detection and
for content security policies.

At its core, a before hook is a class that extends `Brut::FrontEnd::RouteHook` and implements `before`
and an after hook implements `after`.  Both `before` and `after` can be [injected](/keyword-injection) with request-time information.

To register a hook, you'd call `before` or `after` in your `App`:

```ruby
class App < Brut::Framework::App

  # ...

  before :RequireAuthBeforeHook

  # ...

end
```

The value can be a string or symbol, but should not be the class itself, as this can mess with load order.

The code for `RequireAuthBeforeHook` we saw before was marked with a red warning that it wasn't production ready.  Let's
see what a more realistic hook would look like.

The purpose of `RequireAuthBeforeHook` is to detect if a user is logged in.  If they are, all is well. If they are not,
we want to redirect them to a login page unless the page they've requested is allowed for logged-out users.

Let's suppose that the home page (`/`) and any page starting with `/auth/` are allowed for logged-out users (`/auth/` being pages related to logging in).

Brut also reserves some routes for its own, and we want those to be allowed to logged-out users as well. Brut sets
`"brut.owned_path"` in the Rack environment if the requested URL is one it is managing.

`before` will need access to the request context, session, Rack request, and Rack environment:


```ruby
# app/src/front_end/route_hooks/require_auth_before_hook.rb
class RequireAuthBeforeHook < Brut::FrontEnd::RouteHook
  def before(request_context:,session:,request:,env:)
     # ...
  end
end
```

We'll use the Rack request's `path_info` to check for allowed routes, and the aforementioned `env["brut.owned_path"]` to
check for a Brut-owned path:

```ruby {4-6}
# app/src/front_end/route_hooks/require_auth_before_hook.rb
class RequireAuthBeforeHook < Brut::FrontEnd::RouteHook
  def before(request_context:,session:,request:,env:)
    is_home_page       = request.path_info.match(/^\/?$/)
    is_auth_route      = request.path_info.match?(/^\/auth\//)
    is_brut_owned_path = env["brut.owned_path"]

    # ...

  end
end
```

Now, we can use this local variables to figure out if the route requires a user to be logged-in:

```ruby {8-10}
# app/src/front_end/route_hooks/require_auth_before_hook.rb
class RequireAuthBeforeHook < Brut::FrontEnd::RouteHook
  def before(request_context:,session:,request:,env:)
    is_home_page       = request.path_info.match(/^\/?$/)
    is_auth_route      = request.path_info.match?(/^\/auth\//)
    is_brut_owned_path = env["brut.owned_path"]

    requires_login = !is_home_page  &&
                     !is_auth_route && 
                     !is_brut_owned_path

    # ...

  end
end
```

Now, we'll check if someone *is* logged in. If they are, we'll set the `authenticated_account` in the request context.

```ruby {12-15}
# app/src/front_end/route_hooks/require_auth_before_hook.rb
class RequireAuthBeforeHook < Brut::FrontEnd::RouteHook
  def before(request_context:,session:,request:,env:)
    is_home_page       = request.path_info.match(/^\/?$/)
    is_auth_route      = request.path_info.match?(/^\/auth\//)
    is_brut_owned_path = env["brut.owned_path"]

    requires_login = !is_home_page  &&
                     !is_auth_route && 
                     !is_brut_owned_path

    if session.logged_in?
      request_context[:authenticated_account] = session.authenticated_account
      requires_login = false
    end

    # ...

  end
end
```

Now, we can test if the visitor needs to log in before proceeding.  The return value of `before` controls
what will happen, similar to how handlers work.


* `URI` - the browser will be redirected to this URI. This can be done by using the `redirect_to` helper.
* `Brut::FrontEnd::HttpStatus` - the request will be terminated with this status. This can be done using the `http_status` helper.
* `false` - the request is terminated with a 500
* `true` or `nil` - the request will continue to the next hook or to the route handler. You are encouraged to use the `continue` helper to more clearly indicate that the request will proceed.

In our case, if the visitor requires a login, we'll `redirect_to` the `LoginPage`.  Otherwise, we'll
`continue`.

```ruby {17-21}
# app/src/front_end/route_hooks/require_auth_before_hook.rb
class RequireAuthBeforeHook < Brut::FrontEnd::RouteHook
  def before(request_context:,session:,request:,env:)
    is_home_page       = request.path_info.match(/^\/?$/)
    is_auth_route      = request.path_info.match?(/^\/auth\//)
    is_brut_owned_path = env["brut.owned_path"]

    requires_login = !is_home_page  &&
                     !is_auth_route && 
                     !is_brut_owned_path

    if session.logged_in?
      request_context[:authenticated_account] = session.authenticated_account
      requires_login = false
    end

    if requires_login
      redirect_to(Auth::LoginPage)
    else
      continue
    end

  end
end
```

## Testing

Route hooks are normal classes, you could test them as you would a handler or other class.  This may be
advisable for complex hooks, however it may be more realistic to test their behavior through end-to-end
tests as this will ensure they are configured correctly in the context of the app.

## Recommended Practices

Route hooks and [page hooks](/pages#hooks) serve similar purposes, so logic in one can be placed in other
other at your discretion.  We recommend you use route hooks for cross-cutting issues across the entire
app, such as login checks or for adding context to a request.

For page- or use-case-specific behavior, it may be better to put the logic in a page hook.

## Technical Notes

> [!IMPORTANT]
> Technical Notes are for deeper understanding and debugging. While we will try to keep them up-to-date with changes to Brut's
> internals, the source code is always more correct.

_Last Updated June 12, 2025_

Route hooks and Middlewares do not share implementations, however they are similar in concept.  These
concepts may be unified in the future.
