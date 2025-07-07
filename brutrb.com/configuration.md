# Configuration

Brut strives to avoid configuration and flexibility.  Much of Brut's behavior is convention-based, however
several aspects of Brut's behavior relate to literal values like file paths.  Some of this set up is designed to
be overridden.

## Overview

Any configured value, or value otherwise intended to be abstracted from its literal value, is available via
`Brut.container`, which returns an instance of `Brut::Framework::Container`.  This class uses `method_missing` to
provide direct access to configured values. It can also be used to store or override configured values.

An instance of `Brut::Framework::Config` is used to set up all of Brut's initial values.  This file is a good
reference for determining the literal values of various configuration options.

### Basics of Configuration

The configuration system can be used to set literal values, or lazily-derived values.  The method `store` is used
for both purposes.  Lazy values are managed by calling `store` with a block.

::: code-group

```ruby [Storing Litral Values]
Brut.container.store(
  "database_url",
  String,
  "URL to the primary database"
  ENV.fetch("DATABASE_URL")
)
```

```ruby [Storing Lazy Values]
Brut.container.store(
  "database_url",
  String,
  "URL to the primary database"
) do
  # Only evaluated when Brut.container.database_url is called
  ENV.fetch("DATABASE_URL")
end
```
:::

The configuration system also enables dependencies between values.  For example, the Sequel connection to the database requires the URL to the database.  Since `database_url` is configured seperately, `sequel_db_handle` depends on its value.  It declares this by declaring a block parameter with the same name as the configuration option, `database_url` in this case.

```ruby
Brut.container.store(
  "sequel_db_handle",
  Object,
  "Handle to the database",
) do |database_url|
  Sequel.connect(database_url)
end
```

When `Brut.container.sequel_db_handle` is called, the block is examined. Brut sees that it has a parameter named
`"database_url"`, and will then call `Brut.container.database_url` to fetch the value and pass it in.

This reduces repetition amongst the various configuration options.

### Special Types of Configuration

Brut's configuration system enforces some rules, and may enforce more in the future.  It's a strong desire that no
Brut app even boot if the configuration is not usable.

Many of Brut's configuration options are paths.  To avoid having to have a bunch of `.keep` files all over the
plces, Brut allows storing an *ensured path*, which Brut will created when needed.

```ruby
Brut.container.store_ensured_path(
  "images_src_dir",
  "Path to where images are stored"
) do |front_end_src_dir|
  front_end_src_dir / "images"
end
```

If your Brut app has no images at all, when `Brut.container.images_src_dir` is accessed, the path to where the
images should go will be created.

Some paths *must* exist in advance.  For those, `store_required_path` can be used. It throws an error if the path
does not exist:

```ruby
Brut.container.store_required_path(
  "pages_src_dir",
  "Path to where page classes and templates are stored"
) do |front_end_src_dir|
  front_end_src_dir / "pages"
end
```

### Type and Name Enforcement

You'll note that `store` accepts a class parameter.  This is mostly used for documentation, with two exceptions:

* If the type is `Pathname` (which is what is used by `store_ensured_path` and `store_required_path`), the configuration parameter name *must* end in `_file` or `_dir`.
* If the type is `"boolean"` or `:boolean`, the configuration parameter name *must* end in a question mark. In this case, the value itself is coerced into `true` or `false`.

Brut may add more constraints or conversions over time.

### Overridable and `nil`able Values

By default, Brut configuration values cannot be overridden and they cannot be `nil`.  When calling `store`, `allow_app_override: true` and `allow_nil: true`, can be passed to change this behavior.

In [Flash and Session](/flash-and-session), we discussed that you can set your own class for the flash. This is possible due to how Brut defines the configuration parameter `flash_class`:

```ruby {6}
Brut.container.store(
  "flash_class",
  Class,
  "Class to use to represent the Flash",
  Brut::FrontEnd::Flash,
  allow_app_override: true,
)
```

Since `allow_app_override` is true, you can call `override` in your `App`:

```ruby
Brut.container.override("flash_class",AppFlash)
```

Calling `override` for parameters where `allow_app_override` is not true results in an error. Further, calling
`store` on a previously `store`-d parameter results in an error.

The idea is to make it extremely clear what values are being set and overridden, and to avoid setting values that
don't exist or aren't relevant.

Some values can be `nil`.  Generally, `nil` is a pain and will cause you great hardship.  On occasion, it's
needed.  For example, [external IDs](/database-schema#external-ids) only work if the app provides an app-wide
prefix.

Here is how Brut sets this up by default:

```ruby {5-7}
Brut.container.store(
  "external_id_prefix",
  String,
  "String to use as a prefix for external ids in tables using the external_id feature. Nil means the feature is disabled",
  nil,
  allow_app_override: true,
  allow_nil: true,
)
```

Brut defaults this to `nil`, meaning there is no external ID prefix to be used.  Apps can opt into this behavior
by overriding the value:

```ruby
Brut.container.override("external_id_prefix","cc")
```

Conversly, apps can opt *out* of [Content Security Policy Reporting](/security). By default, Brut sets up its own
reporting hook:

```ruby
Brut.container.store(
  "csp_reporting_class",
  Class,
  "Route Hook to use for setting the Content-Security-Policy-Report-Only header",
  Brut::FrontEnd::RouteHooks::CSPNoInlineStylesOrScripts::ReportOnly,
  allow_app_override: true,
  allow_nil: true,
)
```

If you don't want this, you can override it and set it to `nil`:

```ruby
Brut.container.override("csp_reporting_class",nil)
```

`allow_nil` is a good indicator that Brut can handle a `nil` value for that configuration parameter—it wouldn't
allow it if couldn't.

### Setting Your Own Configuration Values

In your `App` class, you can call `store` as needed to setup configuration values relevant to your app.  For
example, if you are using SendGrid to send emails, you may want to set the client up during startup:

```ruby
# app/src/app.rb
class App < Brut::Framework::App

  # ...

  def initialize

    # ...

    Brut.container.store(
      "send_grid_client",
      SendGrid::API,
      "SendGrid API Client",
      SendGrid::API.new(api_key: ENV["SENDGRID_API_KEY"])
    )

    # ...

  end
end
```

Then, elsewhere in your app, you can call `Brut.container.send_grid_client` to access this object. Because
`allow_nil` is not specified (and therefore false), your app can confidently rely on a value being returned.

## Testing

Do not test configuration.  Ideally, the configuration values for production are the same as for dev and test.
If you really cannot use the production value for something in dev or test, you can have your value depend on
`project_env`, which is a `Brut::Framework::ProjectEnvironment`:

```ruby {4-10}
Brut.container.store(
  "send_grid_client",
  SendGrid::API,
  "SendGrid API Client") do |project_env|
    if project_env.testing?
      FakeSendGrid.new
    else
      SendGrid::API.new(api_key: ENV["SENDGRID_API_KEY"])
    end
  end
end
```

## Recommended Practices

Try to avoid project environment-specific behavior.  The less of that you have, the more confidence you will have
that your app will boot in production.

In genreal, configure custom parameters only when you want them to be a check on app startup.  For example, we
don't want our app to even start if `SENDGRID_API_KEY` is not in the environment. If we defered instantiating
`send_grid_client` until the first time we tried to send email, we wouldn't notice things were broken.

Conversely, do not place every object you could ever imagine into the container.  `Brut::Framework::Container` is
not intended as a fully armed and operational dependency injection container. Perhaps someday, but not today.

Lastly, do not `store` or `override` outside of your `App` class' initializer. It will be confusing and
`override` may not work as expected.

## Technical Notes

> [!IMPORTANT]
> Technical Notes are for deeper understanding and debugging. While we will try to keep them up-to-date with changes to Brut's
> internals, the source code is always more correct.

_Last Updated May 7, 2025_

`Brut::Framework::Config` is created and executed in the initializer of `Brut::Framework::MCP`, which happens
before your `App`'s initializer is run.  This also happens when CLI apps run.  Brut tries very hard not to make
network connections inside `Brut::Framework::Config#configure!` for just this reason.

`Brut::Framework::Container` does not really check for circular dependeices, so please try to avoid making them.
If this happens, there will be a stack overflow.
