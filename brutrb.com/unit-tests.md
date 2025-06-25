# Unit Tests

Tests in Brut use RSpec and given that most of your Brut-powered
classes are simple Ruby classes, you can test them in conventional
ways.

## Overview

When you scaffold something like a page or component, Brut will
create an empty test file in `specs/`, whose path mirrors the
class in `app/src`.  For example, `specs/front_end/handlers/login_handler.spec.rb` will test the class defined in `app/src/front_end/handlers/login_handler.rb`.

Each page of Brut's documentation includes a "Testing" section
that outlines additional features avialable to make testing work
more easily.  This section will talk about general features and
behavior.

### Tests run in a Database Transaction

At the start of each test (`it` block in RSpec), a database
transaction is opened.  At the end, the transaction is rolled
back.  This means that none of the changes you make to the
database have any effect outside the context of the test.

The downside of this approach is that you cannot test anything
that involves database transactions.  For example, if you want to
ensure that a piece of business logic runs inside a database
transaction, you will have to assure that another way, such as
spying.

### A Usable `RequestContext` is Created for Front End Tests

Although your tests of pages, components, and handlers are
generally isolated, it's possible to trigger codepaths where Brut
will use [keyword injection](/keyword-injection), such as a
global component.

To make sure this doesn't fail, Brut sets up a reasonable
`RequestContext` that will be used for any such injections.

Brut will also `let` that instance, named `request_context`.  This
means you can access it and modify it in your test as needed.  It
will be recreated new for each test, so you are safe making
changes to it.

### `bin/test audit` and Managing Tests

`bin/test audit` will fail if any file in `app/src` does not have
a corresponding test.  This is handy when you are moving fast to
make sure you don't forget to add test coverage.

That said, sometimes classes are simple and won't benefit from a
test, or a class' behavior may be adequately covered by another
test.  It's helpful to record this information so it's clear that
you've given consideration to tests and not just forgotten them.

Every Brut test has
`Brut::SpecSupport::GeneralSupport::ClassMethods` included and it
provides three methods to help record your intent with respect to
omitting tests. These methods should be called in a `describe` or
`context` block.

* `implementation_is_covered_by_other_tests(description)` used to
explain where the coverage for this class is.

  ```ruby
  RSpec.describe TaxCalculator do
    implementation_is_covered_by_other_tests "e2e tests for checkout"
  end
  ```
* `implementation_is_needed(check_again_at:)` used when you want to acknowledge that a test is required, but for whatever reason you cannot provide it now.  This will create a test that fails after the date/time given to `check_again_at:`.

  ```ruby
  RSpec.describe TaxCalculator do
    implementation_is_needed(check_again_at: "2025-06-13")
  end
  ```
* `implementation_is_trivial(check_again_at: nil)` used to indicate that code is trivial and would not benefit from the carrying cost of a test. `check_again_at:` is optional and this will create a failing test after that date.  You'd set this for a class that you suspect may grow in complexity, as a way to ensure it's not forgotten.

  ```ruby
  RSpec.describe TaxCalculator do
    implementation_is_trivial
  end
  ```
## Recommended Practices

A list of recommended practices for testing could fill many books.
Instead, we'll focus on a few things that will make life easier.

### Go Easy on RSpec Features

Shared contexts and shared examples usually make a test suite much
harder to understand and much worse.  You should avoid them
entirely.

`let` and `let!` also generally make things worse and should be
avoided. It's usually better to have duplication in various `it`
blocks than to try to parameterize the use of `let`.  This is
doubly true when you have nested contexts.

### Custom Matchers Are Useful

An effective way to re-use test assertions is via custom matchers.
Brut makes use of these, and you can easily create your own. The
recommended way to do this is:

1. Create `specs/support/matchers`
2. Create your matcher there, named for the matcher's method. For
   example, if your matcher is `be_active_account`, create
   `specs/support/matchers/be_active_account.rb`.
3. Implement your matcher per RSpec's instructions.
4. Use `require "support/matchers/be_active_account"` to require
   your matcher explicitly. This will make it easier to understand
   where everything is coming from when others read your test.
5. Check your matchers behavior with passing and failing tests and
   for negated versions.  Ensure that `failure_message` and
   `failure_message_when_negated` produce useful messages.

### Lint Your Factories

By default, your Brut app should come with a spec to verify that
all your Factory Bot factories work:

```ruby
# specs/lint_factories.spec.rb
require "spec_helper"
RSpec.describe "factories" do
  it "should be possible to create them all" do
    FactoryBot.lint traits: true
  end
end
```

This implies that each factory and each trait of that factory can
be created without providing any additional attributes.  This is
*critical* to sustainable tests over time.  If any factory can be
created at any time without dependencies, your tests will be easy
to write and maintain.

## Technical Notes

> [!IMPORTANT]
> Technical Notes are for deeper understanding and debugging. While we will try to keep them up-to-date with changes to Brut's
> internals, the source code is always more correct.

_Last Updated May 9, 2025_


