# End-to-End Tests

Brut uses Playwright, which is the worst way to end-to-end test, except for all
the rest.

1. Bookmark [Playwright Ruby Client Documentation](https://playwright-ruby-client.vercel.app/docs/api/playwright) as you will need to consult it frequently.
2. Create your end-to-end test with `brut scaffold`:

   ```bash
   dx/exec brut scaffold e2e_test login
   # => specs/e2e/login.spec.rb
   ```

   Or, to create it in a subfolder of `specs/e2e`

   ```bash
   dx/exec brut scaffold e2e_test login --path=auth
   # => specs/e2e/auth/login.spec.rb
   ```
3. Use `#locator` and CSS selectors. Playwright provides a lot of ways to
   locate elements, and most of them are extremely confusing or have behavior
   that is difficuilt to predict and control. CSS selectors is simplest.

   ```ruby
   it "shows a welcome message" do
     page.goto(HomePage.routing)

     expect(page.locator("h1")).to have_text("Welcome!")
     expect(page.locator("header h2")).to have_text("Brut is Awesome")
   end
   ```
4. Use `be_page_for` after navigating to ensure navigation completes and puts
   you on the correct page

   ```ruby
   it "allows editing preferences" do
     page.goto(HomePage.routing)

     link = page.locator("header nav a[title='Preferences']")

     link.click

     # Waits a fixed amount of time for
     #     <meta name="class" content="PreferencesPage">
     # to show up in the browser, thus waiting for
     # navigation to complete
     expect(page).to be_page_for(PreferencesPage)
   end
   ```
5. Use `with_clues` to dump HTML when your test is failing and you don't know
   why.

   ```ruby
   it "allows editing preferences" do
     page.goto(HomePage.routing)

     link = page.locator("header nav a[title='Preferences']")

     link.click

     with_clues do
       expect(page).to be_page_for(PreferencesPage)
     end
   end
   ```

   When the `expect(page)...` fails, `with_clues` will output the HTML
   of the page at the time the test failed.  This can help debug
   what's going on. Don't leave this in your test - it's for debugging only.

See [End-to-End Tests](/end-to-end-tests) for more.
