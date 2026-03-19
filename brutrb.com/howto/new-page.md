# Add a New Page

Your page's name should be the name everyone uses when talking about it. It
doesn't have to conform to any rules about resources—just name it for what
people call it.

In this example, we'll create the *manage subscriptions page*.  To create this
page, a route, and a test, you'll need to decide on the route, which should be
a `/` followed by the dasherized, lower-cased name of the page (though it can
be anything that is a valid path for a URL).

We'll use `/manage-subscriptions`, and invoke `brut scaffold page` like so:

```bash
dx/exec brut scaffold page /manage-subscriptions
```

This should create a route in `app.rb`, the page's class source code in
`app/src/front_end/pages/manage_subscriptions_page.rb`, a test in
`specs/front_end/pages/manage_subscriptions_page.spec.rb`, and an entry in
`app/config/i18n/en/2_app.rb` for the page's title.

The page's test is failing, as a reminder to write a test for it. You can run
that test specifically via:

```bash
dx/exec brut test run specs/front_end/pages/manage_subscriptions_page.spec.rb
```
