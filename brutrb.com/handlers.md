# Handlers & Actions

Handlers process form submissions, and *actions* work similarly to process any arbitrary HTTP request.

## Overview

Where a [page](/pages) renders a web page in HTML, a *handler* responds to all other HTTP requests.  To respond to such HTTP requests, you'd first create a [route](/routes), using `form`, `action`, or `path`.

### Declaring Routes

`form` and `action` are intended to be used when an HTTP form is being submitted. The latter—`action`—is for when your form has no user-editable elements.  This is akin to Rails' `button_to` helper, where the contents of the URL contains everything needed to service the request.

`path` is for arbitrary HTTP requests and methods, so to create a webhook that responds to a PUT, you'd use:

```ruby
# inside app/src/app.rb
path "/webhooks/stripe", method: :put
```

In all cases, the class to receive and process these requests is a handler, whose name is conventional based on the route. For example, the webhook above would be handled by `Webhooks::StripeHandler`.

### Implementing Handlers

A handler works like a page, in that its initializer can receive any injectible arguments.  These would include a form object, dynamic elements of the route, or anything else available from the request.  See [Keyword Injection](/keyword-injection) for the details, noting that your handler can be inejcted with custom objects you've configured in a route hook.

After the handler is created, it's `before_handle` method is called. If it returns `nil`, `handle` is called to trigger whatever logic the handler needs to trigger.

Both `handle` and `before_handle` can return a variety of objects that determine what will happen:

* An instance of a page or component means that page or component is rendered.  This is not a redirect to the page, so it is more like Rails' `render :new` and **not** a `redirect_to(new_widgets_path)`.
* A `Brut::FrontEnd::HttpStatus` which sends that status and an empty body back.  This object can be created from
an integer using the `http_status` helper, available to all handlers.
* A `URI`, which will cause a redirect to that URI.  You can create the `URI` yourself, or use the helper
`redirect_to`, which accepts a string.
* A two-element array with a page or component as the first element and an `Brut::FrontEnd::HttpStatus` as the
second.  This will render that page  or component's HTML, but use the given status instead of 200.  This can be useful for Ajax requests where you want to use HTML your respond format, but also, say, a 422 status to indicate a constraint violation has occured.
* A `Brut::FrontEnd::Download`, which encapsulates a file to be downloaded.
* A `Brut::FrontEnd::GenericResponse`, which wraps any Rack response with a defined type.

`before_handle` may also return `nil` to indicate that `handle` should be called. `handle` may not return `nil`.

Supposing our `LoginForm` and `LoginHandler` wanted to use a common pattern of re-rendering `LoginPage` on constraint violations, and forwarding on to, say, a `DashboardPage`.  Your handler might look like so:

```ruby {23-27}
# app/src/front_end/handlers/login_handler.rb
class LoginHandler < AppHandler
  def initialize(form:, session:) # We'll discuss the session later
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
        session.authorized_user = authorized_user
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

> [!IMPORTANT]
> The only way to render something other than HTML is to do so as a
> `GenericResponse`, which is basically the low-level Rack API. Brut
> encourages Ajax responses to be HTML and for you to use the browser's
> APIs to interact with that HTML.  Brut may make it easier to work
> with other types of content in the future.

## Testing

Testing handlers requires calling their *public API*, which is `handle!`.  This is not the method you implement (which is the non-bang `handle`).  The reason is that `handle!` manages the logic around calling `before_handle`, which allows your tests to always call `handle!` and know they are testing how the  handler would be used in produciton.

Each handler spec includes `Brut::SpecSupport::HandlerSupport`, which allows you to create production-like flash, clock, and session objects. To assert the results of calling `handle!`, there are several RSpec matchers you can use to make your tests easier to write.

* `have_redirected_to` will check that the handler redirected to a give URI.
* `have_rendered` will check that the handler rendered a specific page
* `have_returned_http_status` will check that the handler returned an HTTP status
* `have_constraint_violation` will check if a form had a particular constraint violation set on it

```ruby
require "spec_helper"

RSpec.describe LoginPage do
  describe "#handle!" do
    context "when login is not valid" do
      it "re-renders LoginPage" do
        form = LoginForm.new(params: {
          email: "nonexistent@example.com",
          password: "not a password",
        })
        result = described_class.new(
          form:,
          session: empty_session # empty_session provided by HandlerSupport
        )
        expect(result).to have_rendered(LoginPage)
        expect(form).to have_constraint_violation(:email, key: :login_not_found)
      end
    end
    context "when login is valid" do
      it "forward to the DashboardPage" do
        user = create(:user, # Assume this is set up via FactoryBot
                      email: "pat@example.com",
                      password: "1q2w3e4r5t6y7u8i9o")

        form = LoginForm.new(params: {
          email: "pat@example.com",
          password: "1q2w3e4r5t6y7u8i9o",
        })
        session = empty_session
        result = described_class.new(
          form:,
          session:,
        )
        expect(result).to have_redirected_to(DashboardPage.routing)
        expect(session.authorized_user).not_to eq(nil)
        # Session will be explained later
      end
    end
  end
end
```

## Recommended Practices

You should avoid having business logic in your handlers.  Since handlers bridge the gap between HTTP and your app, their API is naturally simplistic and String-based.  The handler should defer to business logic (which can be done by either passing the form object directly, or extracting its data and passing that).  Based on the response, the handler will then decide what HTTP response is approriate.

This means that your handlers will be relatively simple and their tests will as well.  It does mean that their tests may require the use of mocks or stubs, but that's fine.  Mocks and stubs exist for a reason.


## Technical Notes

> [!IMPORTANT]
> Technical Notes are for deeper understanding and debugging. While we will try to keep them up-to-date with changes to Brut's
> internals, the source code is always more correct.

_Last Updated May 5, 2025_

None at this time.

