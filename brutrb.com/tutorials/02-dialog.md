# Tutorial: Styled Confirmation Dialog

For actions that can't be undone, it's customary to confirm with the visitor that they are sure they
want to take that action.  Brut provides support for this. You can use `window.confirm` or create your
own styled `<dialog>` that Brut will use.  Both approaches don't require writing any JavaScript
yourself.

[You can watching this as a screencast instead](https://video.hardlimit.com/w/4y8Pjd8VVPDK372mozCUdj).

## Set Up

If you haven't followed the [initial tutorial](/tutorials/01-intro), you'll need to pull down the blog
app so you have a place to work.

1. [Install Docker](https://docker.com)

   > [!TIP]
   > If you are on Windows, we *highly* recommend you use the 
   > Windows Subystem for Linux (WSL2), as this makes Brut, web developement,
   > and, honestly, your entire life as you know it, far easier than trying to
   > get things working natively in Windows.

2. Clone the `blog-demo` repo (**don't use Codespaces as it is not supported**):

   ::: code-group
   ```bash [Terminal]
   git clone git@github.com:thirdtank/blog-demo.git
   ```

   ```bash [GitHub CLI]
   gh repo clone thirdtank/blog-demo
   ```
   :::

3. `cd` to what you just cloned.

   ```bash
   cd blog-demo
   ```

4. Create a branch named `confirmation-dialog` off of the `02-confirmation-dialog/start` branch:

   ```bash
   git checkout -b confirmation-dialog 02-confirmation-dialog/start 
   ```
5. Build your development image.

   ```bash
   dx/build
   ```

6. Start the environment, which will pull down Postgres and otel-desktop-viewer

   ```bash
   dx/start
   ```

7. In another terminal window, "log in" to your dev environment (note that you can use your editor on your computer to edit code)

   ```bash
   dx/exec bash
   ```

8. Set up and run tests to make sure things are working before you start making changes. Note, this is
   **inside the container**, not directly on your computer.

   ```bash
   bin/setup
   bin/ci
   ```

## What We're Doing

When writing a blog post, if the title and content satisfy all constraints, the post is saved and shown
on the home page.  Because this can't currently be undone, we want the user to confirm the posting, just
to avoid any accidents.

Initially, we will use `window.confirm` to do this.  After that, we'll create a nicely styled dialog to
do the confirmation. While this will require that the browser execute JavaScript, we won't be writing any. We'll use Brut-provided Web
Components to do this.

![Diagram showing the flow, with a screenshot of the blog post editor on the left, and a pink arrow from
the 'Post it' button going to the text 'Are You Sure?'. From there, a pink line labeled 'No' goes back
to the editor, while a pink line labeled 'Yes' goes to a screenshot of the home page showing the blog
post.](/images/tutorial/02-confirmation-flow.png)

## Initial Version Using `window.confirm`

Brut includes an [autonomous custom
element](https://developer.mozilla.org/en-US/docs/Web/API/Web_components/Using_custom_elements) named
`<brut-confirm-submit>`.  This element wraps an existing submit button and intercepts its form
submission to ask for confirmation. If confirmation is granted, the form is submitted. If not, it's not.

It is used on a per-button basis, which gives you flexibility in handling what buttons do what within
the form.  It *only* works on `<button>` and `<input type="submit">` elements.

```html
<form ...>
  <input ...>
  <brut-confirm-submit message="You sure?">
    <button>Submit</button>    <!-- if clicked, confirmation is requested -->
  </brut-confirm-submit>
  <button>Also Submit</button> <!-- if clicked, form is submitted -->
</form>
```

### Adding Confirmation to Blog Posting

We can use it on `BlogPostEditorPage`.  Open up `app/src/front_end/pages/blog_post_editor_page.rb` and
make this change toward the end of `page_template`

```ruby:line-numbers=21 {1-3,5}
brut_confirm_submit(
  message: "This will post immediately to the home page"
) do
  button { t([:form,:post]) }
end
```

The method `brut_confirm_submit` is provided by Phlex due to a call to
[`register_element`](https://www.phlex.fun/sgml/html-elements.html#custom-elements) in
`Brut::FrontEnd::Component`.

Now, start up your server using `bin/dev`:

```bash
bin/dev
```

```txt
# OUTPUT
« LOTS OF OUTPUT »
15:50:10 startup_message.1 | Your app is now running at
15:50:10 startup_message.1 | 
15:50:10 startup_message.1 |   http://localhost:6502
15:50:10 startup_message.1 | 
```

Open `http://localhost:6502` in your browser, then click "Write New Blog Post", write a valid post and click "Post It".  You
should see the browser's `window.confirm` show up with the value for `message:` as the message.

![Screenshot showing the browser's builtin confirmation dialog](/images/tutorial/02-confirmation-dialog-browser.png)

Click "Cancel" and the dialog goes away and nothing is posted.  Click "Post It" again, then click "OK", and the post goes through as normal.

Even though we are going to build our own dialog, let's keep our end-to-end test working.

### Interacting with `window.confirm` in End-to-End Tests

Let's start by seeing how the test fails:

```bash
bin/test e2e
```

```txt {20-21,33}
# OUTPUT
> bin/test e2e
[ bin/test ] Rebuilding test database schema
[ bin/test ] Executing ["bin/db rebuild --env=test"]
[ bin/db ] Database exists. Dropping...
[ bin/db ] blog_test does not exit. Creating...
[ bin/db ] Migrations applied
[ bin/test ] ["bin/db rebuild --env=test"] succeeded
[ bin/test ] Running all tests
[ bin/test ] Executing ["bin/rspec -I /Users/davec/Projects/ThirdTank/blog-demo/specs -I /Users/davec/Projects/ThirdTank/blog-demo/app/src -I lib/ --tag e2e -P \"**/*.spec.rb\" /Users/davec/Projects/ThirdTank/blog-demo/specs/"]

«TONS OF OUTPUT»

Failures:

  1) We can post a new blog post allows posting a post
     Failure/Error: expect(content_error_message).to have_text("This field does not have enough words")

       /Users/davec/Projects/ThirdTank/blog-demo/local-gems/gem-home/gems/playwright-ruby-client-1.52.0/lib/playwright/locator_assertions_impl.rb:53:in 'Playwright::LocatorAssertionsImpl#expect_impl':  (Playwright::AssertionError)
       Locator expected to have text 'This field does not have enough words'
       Actual value <element(s) not found> 
       Call log:
        - locator#Playwright::Locator#expect with timeout 5000ms
         - waiting for locator("brut-cv-messages[input-name='content'] brut-cv")
       	from /Users/davec/Projects/ThirdTank/blog-demo/local-gems/gem-home/gems/playwright-ruby-client-1.52.0/lib/playwright/locator_assertions_impl.rb:397:in 'Playwright::LocatorAssertionsImpl#to_have_text'

«MASSIVE STACK TRACE»

       	from /Users/davec/Projects/ThirdTank/blog-demo/local-gems/gem-home/gems/rspec-core-3.13.5/lib/rspec/core/runner.rb:45:in 'RSpec::Core::Runner.invoke'
       	from /Users/davec/Projects/ThirdTank/blog-demo/local-gems/gem-home/gems/rspec-core-3.13.5/exe/rspec:4:in '<top (required)>'
       	from bin/rspec:16:in 'Kernel#load'
       	from bin/rspec:16:in '<main>'
     # ./specs/e2e/home_page.spec.rb:34:in 'block (2 levels) in <top (required)>'

«MASSIVE STACK TRACE»

     # ./local-gems/gem-home/gems/brut-0.5.0/lib/brut/spec_support/rspec_setup.rb:129:in 'block in Brut::SpecSupport::RSpecSetup#setup!'

Finished in 7.6 seconds (files took 0.7169 seconds to load)
1 example, 1 failure

Failed examples:

bin/test run ./specs/e2e/home_page.spec.rb:4 # We can post a new blog post allows posting a post

Randomized with seed 25427

[ bin/test ] error: ["bin/rspec -I /Users/davec/Projects/ThirdTank/blog-demo/specs -I /Users/davec/Projects/ThirdTank/blog-demo/app/src -I lib/ --tag e2e -P \"**/*.spec.rb\" /Users/davec/Projects/ThirdTank/blog-demo/specs/"] failed - exited 1
```

I've highlighted the relevant parts.  Playwright loves stack traces and obtuse errors.

Let's look at line 34 of `specs/e2e/home_page.spec.rb`:

```ruby {11}
expect(title_error_message).to   have_text("This field is too short")
expect(content_error_message).to have_text("This field is required")

title_field.fill("New blog post")
content_field.fill("Too short")

submit_button.click

expect(page).to be_page_for(BlogPostEditorPage)

expect(content_error_message).to have_text("This field does not have enough words")

content_field.fill("This is a longer post, so we should be OK")

submit_button.click
expect(page).to be_page_for(HomePage)
```

The test was expecting to hit the server and re-generate the page with a server-side error message.
Although `<brut-confirm-submit>` did not pop up when there were client-side constraint violations, it
doesn't know there are server-side ones, so it is waiting for us to confirm the submission.

Playwright will [automatically dismiss any browser-based dialogs](https://playwright.dev/docs/dialogs).
To handle them, our test will need to register a handler.  To do this with Ruby, we'll call `page.on`
and given it an event name and a block to handle the event.

The event name is "dialog" and a Playwright `Dialog` will be passed.  We can call `accept` on that.

Here's the change. Note the line numbers for reference in the file. You want to set this up before
`submit_button.click` is called.

```ruby:line-numbers=28 {3-6}
   content_field.fill("Too short")

   accept_dialog = ->(dialog) {
     dialog.accept
   }
   page.on("dialog",accept_dialog)

   submit_button.click
```

Note that this configuration will stay in effect for the rest of the test. That means when we later save
the blog post, it will accept the dialog.

Now, `bin/test e2e` should pass:

```bash
bin/test e2e
```

```txt {14}
#OUTPUT
[ bin/test ] Rebuilding test database schema
[ bin/test ] Executing ["bin/db rebuild --env=test"]
[ bin/db ] Database exists. Dropping...
[ bin/db ] blog_test does not exit. Creating...
[ bin/db ] Migrations applied
[ bin/test ] ["bin/db rebuild --env=test"] succeeded
[ bin/test ] Running all tests
[ bin/test ] Executing ["bin/rspec -I /Users/davec/Projects/ThirdTank/blog-demo/specs -I /Users/davec/Projects/ThirdTank/blog-demo/app/src -I lib/ --tag e2e -P \"**/*.spec.rb\" /Users/davec/Projects/ThirdTank/blog-demo/specs/"]

«TONS OF OUTPUT»

Finished in 3.57 seconds (files took 0.7341 seconds to load)
1 example, 0 failures

Randomized with seed 1445

[ bin/test ] ["bin/rspec -I /Users/davec/Projects/ThirdTank/blog-demo/specs -I /Users/davec/Projects/ThirdTank/blog-demo/app/src -I lib/ --tag e2e -P \"**/*.spec.rb\" /Users/davec/Projects/ThirdTank/blog-demo/specs/"] succeeded
[ bin/test ] Re-Rebuilding test database schema
[ bin/test ] Executing ["bin/db rebuild --env=test"]
[ bin/db ] Database exists. Dropping...
[ bin/db ] blog_test does not exit. Creating...
[ bin/db ] Migrations applied
[ bin/test ] ["bin/db rebuild --env=test"] succeeded
```

`window.confirm` is great in a pinch, but we'd like to use our own styled dialog if possible.

## Using a Styled Dialog

The [`<dialog>`](https://developer.mozilla.org/en-US/docs/Web/HTML/Reference/Elements/dialog) element
has been available since 2022 and provides some of what we'll need to confirm a blog post.  Brut
can enhance a `<dialog>` to act as a confirmation dialog by using the `<brut-confirmation-dialog>`
custom element.

Like `<brut-confirm-submit>`, it wraps an element and enhances it.  To work, the `<dialog>` must include
certain elements to represent the message, a button for consent, and a button for denial.

Let's see it in action.

### Creating a Styled Dialog

Edit `app/src/front_end/pages/blog_post_editor_page.rb` and add the dialog at the end of `page_template`:

```ruby:line-numbers=21 {8-16}
    brut_confirm_submit(
      message: "This will post immediately to the home page"
    ) do
      button { t([:form,:post]) }
    end
  end
end
brut_confirmation_dialog do
  dialog do
    h1
    div do
      button(value:"ok")
      button(value:"cancel") { "Don't Publish" }
    end
  end
end
```

Your browser should provide a default visual style for the dialog (that is terrible), but you can see
that `<brut-confirm-submit>` will now use it when you click "Post It":

![Screenshot showing the browser's styling of a dialog element](/images/tutorial/02-confirmation-dialog-browser-element.png)

`<brut-confirm-submit>` and `<brut-confirmation-dialog>` work together to allow you to style these
dialog how you'd like.  It expects an `h1` element inside where the message will go.  It expects a
`<button value="ok">` that, when clicked, indicates the visitor is accepting the dialog. A `<button
value="cancel">` should also be present that, when clicked, indicates the visitor wants to abort and not
submit the form.

If you've never worked with a `<dialog>` before, it can be handy to set `open` on the element so it
shows up without having to click something to open it. It doesn't show exactly as it would when we use
JavaScript to show it, but it's good enough to get your styling work done:

```ruby
dialog(open: true) do
  # ...
end
```

Here's the CSS I chose. Add this to `app/src/front_end/css/index.css`, inside the `.BlogPostEditorPage` block:

```css:line-numbers=59 {7-44}
      cursor: pointer;
      &:hover {
        background-color: #ACFFAC;
      }
    }
  }
  brut-confirmation-dialog dialog {
    border-radius: 1rem;
    border-width: 0;
    box-shadow: rgb(200, 200, 200) 1px 1px 12.72px 3.46892px;
    background-color: white;
    padding: 1rem;
    h1 {
      color: black;
      font-size: 2rem;
    }
    div {
      width: 100%;
      display: flex;
      gap: 0.25rem;
      align-items: center;
      justify-content: space-between;
      button {
        padding-left: 2rem;
        padding-right: 2rem;
        padding-top: 1rem;
        padding-bottom: 1rem;
        border-radius: 1rem;
        font-size: 150%;
        align-self: end;
        cursor: pointer;
        &[value="ok"] {
          background-color: #E5FFE5;
          border: solid thin #006300;
          color: #006300;
        }
        &[value="cancel"] {
          background-color: #FFE5E5;
          border: solid thin #630000;
          color: #630000;
        }
      }
    }
  }
}
brut-cv {
  display: none;
  color: #A60053;
```

Now, reload the page and click "Post It". You should see a somewhat nicer dialog:


![Screenshot showing the our styling of a dialog element](/images/tutorial/02-confirmation-dialog-browser-element-styled.png)

And, sure enough if you click "Don't Publish", the dialog clears and nothing happens. If you click
"Post It!", it submits the form.

A few notes on how this works:

* The contents of the `<h1>` come from the `message` attribute of the **`<brut-confirm-submit>`**. This
allows you to re-use the confirmation dialog for other purposes.
* The content of the `<button value="ok" ...>` is the same as the button wrapped by
`<brut-confirm-submit>`.

Also note how the use of semantic and standard HTML allows us to style the elements without classes or
`data-` tags.

Let's look back at our tests.

### Interacting with Our Dialog in Tests

Run our end-to-end test:

```bash
bin/test e2e
```

It should fail:

```txt {18,19,33}
#OUTPUT
> bin/test e2e
[ bin/test ] Rebuilding test database schema
[ bin/test ] Executing ["bin/db rebuild --env=test"]
[ bin/db ] Database exists. Dropping...
[ bin/db ] blog_test does not exit. Creating...
[ bin/db ] Migrations applied
[ bin/test ] ["bin/db rebuild --env=test"] succeeded

«TONS OF OUTPUT»

Failures:

  1) We can post a new blog post allows posting a post
     Failure/Error: expect(content_error_message).to have_text("This field does not have enough words")

       /Users/davec/Projects/ThirdTank/blog-demo/local-gems/gem-home/gems/playwright-ruby-client-1.52.0/lib/playwright/locator_assertions_impl.rb:53:in 'Playwright::LocatorAssertionsImpl#expect_impl':  (Playwright::AssertionError)
       Locator expected to have text 'This field does not have enough words'
       Actual value <element(s) not found> 
       Call log:
        - locator#Playwright::Locator#expect with timeout 5000ms
         - waiting for locator("brut-cv-messages[input-name='content'] brut-cv")
       	from /Users/davec/Projects/ThirdTank/blog-demo/local-gems/gem-home/gems/playwright-ruby-client-1.52.0/lib/playwright/locator_assertions_impl.rb:397:in 'Playwright::LocatorAssertionsImpl#to_have_text'
       	from /Users/davec/Projects/ThirdTank/blog-demo/local-gems/gem-home/gems/playwright-ruby-client-1.52.0/lib/playwright_api/locator_assertions.rb:642:in 'Playwright::LocatorAssertions#to_have_text'

«HUGE STACK TRACE»

       	from /Users/davec/Projects/ThirdTank/blog-demo/local-gems/gem-home/gems/rspec-core-3.13.5/lib/rspec/core/runner.rb:45:in 'RSpec::Core::Runner.invoke'
       	from /Users/davec/Projects/ThirdTank/blog-demo/local-gems/gem-home/gems/rspec-core-3.13.5/exe/rspec:4:in '<top (required)>'
       	from bin/rspec:16:in 'Kernel#load'
       	from bin/rspec:16:in '<main>'
     # ./specs/e2e/home_page.spec.rb:39:in 'block (2 levels) in <top (required)>'

«HUGE STACK TRACE»

     # ./local-gems/gem-home/gems/brut-0.5.0/lib/brut/spec_support/rspec_setup.rb:185:in 'Brut::SpecSupport::RSpecSetup::OptionalSidekiqSupport#disable_sidekiq_testing'
     # ./local-gems/gem-home/gems/brut-0.5.0/lib/brut/spec_support/rspec_setup.rb:129:in 'block in Brut::SpecSupport::RSpecSetup#setup!'

Finished in 8.31 seconds (files took 0.66944 seconds to load)
1 example, 1 failure

Failed examples:

bin/test run ./specs/e2e/home_page.spec.rb:4 # We can post a new blog post allows posting a post

Randomized with seed 29349

[ bin/test ] error: ["bin/rspec -I /Users/davec/Projects/ThirdTank/blog-demo/specs -I /Users/davec/Projects/ThirdTank/blog-demo/app/src -I lib/ --tag e2e -P \"**/*.spec.rb\" /Users/davec/Projects/ThirdTank/blog-demo/specs/"] failed - exited 1
```

Line 39 is the same line that failed when we first added the confirmation.  Since Playwright interacts
with browser dialogs via an event, the event listener we added is never fired, so our error is simply
that the page didn't refresh.

Let's remove the listener and instead interact with the new dialog.  We should click "cancel" to make
sure it doens't do anything, then click "ok".

One problem with Playwright (well, with web pages in general) is that it's not easy to assert that
something didn't happen or isn't there. We can't click the cancel button, then assert that there is no
error message.

Instead, we'll assert that the dialog is not being shown.

To do that, we'll locate the dialog, the ok button, and the cancel button.  The assertion that the
dialog isn't shown requires accessing the JavaScript `open` property and checking that it's false.  The
rest of the test works as before, punctuated with calls to `dialog_ok_button.click` to accept the
dialog.

```ruby:line-numbers=25 {6-8,12,13,15,16,25}
expect(content_error_message).to have_text("This field is required")

title_field.fill("New blog post")
content_field.fill("Too short")

dialog               = page.locator("brut-confirmation-dialog dialog")
dialog_ok_button     = page.locator("brut-confirmation-dialog button[value='ok']")
dialog_cancel_button = page.locator("brut-confirmation-dialog button[value='cancel']")

submit_button.click

dialog_cancel_button.click
expect(dialog).to have_js_property(:open,false)

submit_button.click
dialog_ok_button.click

expect(page).to be_page_for(BlogPostEditorPage)

expect(content_error_message).to have_text("This field does not have enough words")

content_field.fill("This is a longer post, so we should be OK")

submit_button.click
dialog_ok_button.click
expect(page).to be_page_for(HomePage)

new_post = DB::BlogPost.order(Sequel.desc(:created_at)).first
```

The test should now pass:

```bash
bin/test e2e
```

```txt {15}
#OUTPUT
[ bin/test ] Rebuilding test database schema
[ bin/test ] Executing ["bin/db rebuild --env=test"]
[ bin/db ] Database exists. Dropping...
[ bin/db ] blog_test does not exit. Creating...
[ bin/db ] Migrations applied
[ bin/test ] ["bin/db rebuild --env=test"] succeeded

«TONS OF OUTPUT»

[7215] - Goodbye!
[7215] - Gracefully shutting down workers...

Finished in 3.45 seconds (files took 0.71481 seconds to load)
1 example, 0 failures

Randomized with seed 30988

[ bin/test ] ["bin/rspec -I /Users/davec/Projects/ThirdTank/blog-demo/specs -I /Users/davec/Projects/ThirdTank/blog-demo/app/src -I lib/ --tag e2e -P \"**/*.spec.rb\" /Users/davec/Projects/ThirdTank/blog-demo/specs/"] succeeded
[ bin/test ] Re-Rebuilding test database schema
[ bin/test ] Executing ["bin/db rebuild --env=test"]
[ bin/db ] Database exists. Dropping...
[ bin/db ] blog_test does not exit. Creating...
[ bin/db ] Migrations applied
[ bin/test ] ["bin/db rebuild --env=test"] succeeded
```

## Areas for Self-Exploration

* Extract the dialog into its own component
* Use Internationalization for all the dialog values

