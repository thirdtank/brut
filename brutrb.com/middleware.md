# Middleware

Brut supports Rack Middleware.

## Overview 

Similar to [route hooks](/hooks), Brut supports Rack Middleware, which is a lower-level way of modifying a
request or changing behavior.

Middleware is recommended if what you want to do is not dependent on your application's code or classes
and is relatively simple.

To use a middleware, create the class in `app/src/front_end/middleware/`. You are encouraged to extend
`Brut::FrontEnd::Middleware`, however this is an empty class currently. It could grow to have helper
methods you'll find useful.

The class itself should conform to Rack's specification, which is typically that it will be given the Rack
"app" in the initializer, and then have a method `call` which will be given the Rack environment.

Here's a middleware that adds a tag to the environment for paths that are "special" to our app, which in
this case means they start with `/special`:

```ruby
class TagSpecialPathsMiddleware < Brut::FrontEnd::Middleware

  def initializer(app)
    @app = app
  end

  def call(env)
    if env["PATH_INFO"] =~ /^\/special\//
      env["app.special_path"] = true
    end
    @app.call(env)
  end
end
```

To use this middleware, call `use` with the class name as a string inside `App`:

```ruby
class App < Brut::Framework::App

  # ...

  use :TagSpecialPathsMiddleware

  # ...
end
```

Don't use the actual class as this can create load order issues.

## Testing

Like hooks, Rack middleware can be tested as a normal class.  That said, you are encouraged to test the
middleware as part of an end-to-end test if possible, since this will ensure it's configured properly in
the context of your app.

## Recommended Practices

Middleware should be used when its logic can be entirely based on the Rack environment passed-in.  While
your database models and other classes should be available, excessive use of your domain logic in a
middleware can create a confusing situation.

## Technical Notes

> [!IMPORTANT]
> Technical Notes are for deeper understanding and debugging. While we will try to keep them up-to-date with changes to Brut's
> internals, the source code is always more correct.

_Last Updated June 12, 2025_

Route hooks and Middlewares do not share implementations, however they are similar in concept.  These
concepts may be unified in the future.

`use` and the way Middleware behaves follows Sinatra's implementation as Brut is currently based on
Sinatra. This may not always be the case, however as things change, we will do our best to ensure the
semantics remain the same.  Nevertheless, it's advisable to have end to end tests assert the behavior of
your configured middleware and not just a unit test of the class itself.
