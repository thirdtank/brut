# Space/Time Continuum - Making Sense of Times and Time Zones

Time zones are the worst.  But they are fact of life.  This means that answer a question like "what is the date?"
or "is it Monday?" are not that easy to answer.

## Timezones Outside of Web Requests

For back-end code, storing dates to the database, etc., Brut falls back to the normal Ruby app mechanisms for
determining the "current time zone", which is to say, it super duper depends.  The system, the database, and Ruby
can all configure a time zone that is in effect when dates are parsed or stored.

The main way to deal with this is in how [Brut manages your database schema](/database-schema), which is to say that it
defaults to using `timestamp with time zone` and encourages you to do the same.  What this data type means is if
your system is set to UTC, stores a timestamp, then restarts with the time zone set to America/Los\_Angeles, that timestamp will be read back without ambiguity.  If you use `timestamp without time zone` (which is typically `timestamp`), this will not be the case.

All this is to say, if you use `timestamp with time zone`, you should generally not have to worry about this.
Just be careful when serializing these values.

## Timezones for User Sessions

Depending on what your app does, you may need to show dates or times to the site visitor.  And you'll probably
want to show those in their time zone.  Brut can help with this.

As mentioned in [Flash and Session](/flash-and-session), the session provides access to timezone information.
Brut also provides a `Clock` class that represents the current date and time in the current session's time zone.
Here is how that works.

There are two ways to determine a visitor's time zone: you can ask them, or you can ask their browser.

### Getting Timezone from the Browser

The default `<head>` section of your app's `DefaultLayout` will include the Brut-provided custom element
`<brut-locale-detection>`. This HTML custom element is configured to communicate the browser's locale and
timezone back to Brut at the URL `/__brut/local_detection`, which is handled by
`Brut::FrontEnd::Handlers::LocaleDetectionHandler`.

The custom element uses `Intl.DateTimeFormat().resolvedOptions().timeZone` to determine the browser's timezone
and sends this back to Brut. Whatever this value is, it will be set in the session as `timezone_from_browser`.
When you ask the session for the `timezone_from_browser`, Brut will attempt to locate a `TZInfo::Timezone` with
that name. If it finds one, that is returned.  Otherwise, `nil` is returned.

This is only part of how Brut determines the session's time zone.

### Getting the Session's Timezone

If you ask the session instead for `timezone`, and it has not been set explicitly, 
Brut will first check `timezone_from_browser`. If it's not `nil`, it's returned. If it *is* `nil`, the timezone
whose name is in `ENV['TZ']` is returned, unless that is missing or invalid, in which case UTC is returned.

If you have a way to ask the user what their timezone is, you can set it via `session.timezone=`. If you have
done this, *that* value is returned instead of the above logic.

Note that in all cases, the timezone that is serialized into the session is the name. This means it's technically
possible for the name to valid when stored and invalid when read, if you have updated the `tzinfo` gem and
something changed.

Therefore, it's recommended that if you have asked the visitor their preferred time zone, you store that
somewhere in the database, so you can detect when the value from the session has drifted.

### Using the Timezone

With a `TZInfo::Timezone` object, you can certainly create a Ruby `Time` object via
`timezone.to_local(Time.new)`.  However, you don't have to do this.  By [keyword injecting](/keyword-injection)
`clock:`, you will get an instance of `Clock`, primed with the value of `session.timezone` as its timezone.

The `Clock` responds to `now` and `today`, and will return the current timestamp and current date, respectively, in the visitor's time zone.  This means that if your view code does something like `l(clock.now, format: :date)`, it will show the current time in the visitor's time zone.

This, coupled with the use of `timestamp with time zone`, means these values can be safely sent to the back-end
to be stored in the database, and conversion is not necessary.

## Testing

If your app makes heavy use of timezone-based timestamps or dates, you are encouraged to test this logic. `Brut::SpecSupport::ClockSupport` (included by default in page, component, and handler tests) provides helper methods to manipulate and use `Clock` instances.  You should not need to mock time or use something like Timecop.

If your tests just need a clock, or a clock at a time, regardless of time zone, you can use `real_clock` or
`clock_at(now:)` to pass into your pages, components, and handlers.  These will be set at UTC.

If your tests require a particular timezone, you may use `clock_in_timezone_at(timezone_name:, now:)`. The
timezone name is from `tzinfo`'s database. `clock_in_timezone_at` will raise an error if given an invalid
timezone.  `now:` is a string that will be parsed as a `Time`.

If you are testing something that is sensitive to time, but you do not have access to the clock, `Brut::SpecSupport::SessionSupport` provides `empty_session`, which returns a session object on which you can call `timezone=`.  Beyond this, you may need to provide hooks for setting the time, for example via a query string parameter.



