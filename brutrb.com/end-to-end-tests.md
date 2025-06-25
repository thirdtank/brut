# End to End Tests

Is there a greater pain the world than an end-to-end test? Is there a more punishing API than trying to
convince a browser to browse and use a website?  Is there an answer for why the way we interact with
browsers when writing code is 100% different than the we do when writing a test?

Brut cannot answer these things, but it does provide a way to write end-to-end tests with a browser, with
a somewhat slightly reduced amount of pain.

## Overview

Brut uses [Playwright](https://playwright.dev/) and the
[playwright-ruby-client](https://playwright-ruby-client.vercel.app/) to allow you to write end-to-end
tests that use a web browser.  Brut sets up headless Chromium to do this.

You can run End-to-End (e2e) tests with `bin/test e2e`.  You must use this to run individual tests as
well, since this will ensure proper set up for the tests, which is more than is needed for a normal unit
test.

### Using Playwright

At a high level, e2e tests look like normal RSpec tests:

```ruby
require "spec_helper"

RSpec.describe "logging into the website" do

  # ...

end
```

The contents of your `it` blocks will use `playwright-ruby-client` to interact with the browser and make
assertions.  The value `page` is available to use this API.

```ruby
require "spec_helper"

RSpec.describe "logging into the website" do
  it "shows an error when login is invalid" do
    page.goto("/")

    email     = page.locator("form input[type='email']")
    password  = page.locator("form input[type='password']")
    button    = page.locator("form button")

    email.fill("pat@example.com")
    password.fill("12345678")
    button.click

    flash = page.locator("[role='alert']")
    expect(flash).to have_text("No email/password in our system")
  end
end
```

`playwright-ruby-client` provides excellent documentation on how it has adapter Playwright's API for use
in Ruby.

### Test Setup

Brut will run your app via `Brut::SpecSupport::E2ETestServer`.  It will run it before the first e2e test, leave it running during the remainder of the test suite, then stop it. This means that database changes your test makes will persist across tests.

If you are using Sidekiq, Sidekiq will be set up like normal. Jobs queued will go to Redis, and those jobs
will be processed by Sidekiq, just like in production.  Thus, you should not assert things about specific
jobs, but rather assert the effects those jobs will have. Redis is flushed between each test.

### Test Helpers and Configuration

Inside your test, `t` is available to produce translations. You can also access all your page and handler classes, so you can (and should) use `.routing`, e.g. `DashboardPage.routing`, to generate or access routes for your app.

You can set `e2e_timeout` on any test to override the default amount of time Playwright will wait for a
locator to locate an element. The default is 5 seconds.
`, to generate or access routes for your app.
You can also configure behavior with environment variables:

| Variable            | Default | Purpose                                                                                           |
|---------------------|---------|---------------------------------------------------------------------------------------------------|
| `E2E_TIMEOUT_MS`    | 5000    | Number of milliseconds Playwright will wait for a locator to appear                               |
| `E2E_SLOW_MO`       | 0       | Number of milliseconds Playwright will pause between operations. Useful to detect race conditions |
| `E2E_RECORD_VIDEOS` | unset   | If set, videos of each test run are saved in `tmp/e2e-videos`                                     |


### Quirks of Playwright

The Playwright JavaScript API is heavily asycnhronous, requiring liberal use of `await`. The
`playwright-ruby-client` wrapper abstracts that so you can write more straightfoward code.

The main thing to be aware of is that locators that fail only fail when you attempt to assert something.

For example

```ruby
button = page.locator("form button") # suppose this button doesn't exist

button.click # This is where you'll see a failure
```

This hidden asynchronous behavior also means that certain calls will wait a period of time for the element
you are locating to appear.  This is why the example test above works without having to explicitly wait
for a page refresh.  After `button.click`, presumably the back-end is contacted and the page is
re-rendered with an error.  As long as that happens within a second or so, the code will wait for an
element matching `[role='alert']` to show up.

## Recommended Practices

E2e tests are slow. They can also be flaky if you aren't careful in how you write them and how you
author your HTML.

### Test Major Flows, Not Exhaustive Branches

E2e tests give the most value when they assert that a sequence of actions the visitor takes result in what
you expect—a "major flow".  Testing some error cases can be useful, but you should not use e2e tests to
assert every single possible thing that could happen on a page.

In fact, your app might be better off leaving some behaviors better untested instead of tested by an e2e test.  Use your judgement and be aware of the carrying cost of each e2e test.

### Use CSS Selectors

The main Playwright documentation encourages you to locate elements by "accessible names" and other
indirect ways of finding elements.  In practice, this is error prone and tedious.  Determining the
accessible name of an element is not always easy.

We recommend you assess your app's accssibility in another way than trying to do it while performing
end-to-end tests.  Instead, locate elements with CSS selectors—this is what you'd use to debug your app so
it makes sense as a testing technique.

Insulating your end-to-end tests from markup changes does not produce significant savinsg and can make
tests more difficult to write.

### Testing Must Inform your HTML

To allow CSS selectors to survive minor changes to a page, your HTML should be authored with testing in
mind.  In the example above, we locate the flash by looking for `[role='alert']`, since this is the most
semantically correct way to mark up a flash message that contains an error.

ARIA roles that should be applied for accessibility purposes can be leveraged as locators, as can custom
elements.  Remember that any custom element is valid, even if it has no associated JavaScript.  Custom
elements are an excellent way to "tag" markup for use in tests or progressively-enhanced behavior.

CSS classes, on the other hand, are not a good candidate for identifying markup in a test. CSS classes
exist to afford visual styling of elements and are the most likely to change as the app evolves.  A better
fallback if there is no other way to locate an element is to use `data-testid`.  It makes itself painfully
clear why it's there.  Use this sparingly, but it's there if you need it.

### Asserting the Lack of Content Basically Doesn't Work

To assert that some content or an element **is not** on the page requires locating it and waiting the
timeout for that locate to fail. This sucks. Don't do it.

If you need to assert that something did not happen, you may want to design your page or app such that
markup appears that indicates whatever it is didn't happen.  This is not ideal, but a web page is a living
thing that never stops changing, so your test can't just assume it's all synchronous.

### Try to Use the Defaults for Timeouts

Your app should not take 5 seconds to do anythning, especially not inside a test.  You may need to bump up
the timeout to figure out what's going wrong, or set `E2E_SLOW_MO` to watch a video test, but once you've
sorted out the issue, restore these to their defaults.

If you *must* set `e2e_timeout` as metadata on test, **explain why** and try removing it every so often to
make sure it's still needed.

## Technical Notes

> [!IMPORTANT]
> Technical Notes are for deeper understanding and debugging. While we will try to keep them up-to-date with changes to Brut's
> internals, the source code is always more correct.

_Last Updated June 13, 2025_

The test server is run bin `bin/test-server`, which is why Sidekiq will be running when your app is
running for an e2e test.
