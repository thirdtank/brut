# Testing a Page

Unlike most classes, pages should be tested by asserting things about the HTML
they generate.  Brut provides helpers for this.

## Use the Correct Helper

* **Use `generate_and_parse` most of the time.** Unless you are testing a page's before hook, call `generate_and_parse` on your page instance.  This will return a `Brut::SpecSupport::EnhancedNode`, which delegates to Nokogiri to allow asserting the HTML the page generated.
* **Use `generate_result` only when testing before hooks.** If your page has a `before_generate` method and you wish to test its behavior, call `generate_result` and assert on that result.

## Asserting HTML

`Brut::SpecSupport::EnhancedNode` provides three helper methods you will use
almost all of the time. It delegates to Nokogiri, which contains a fourth
method you will use occasionally (though you are free to use any Nokogiri method you like)

* `e!(css_selector)` - returns the element matching the selector, failing the
test if there is not exactly one element matching that selector.
* `e(css_selector)` - returns the element matching the selector or `nil`, failing the test if there is more than one element matching the selector.
* `first!(css_selector)` - returns the first element matching the selector,  failing the test if there are no elements matching that selector.
* `css(css_selector)` - Nokogiri's method to locate by CSS selector. This will
return zero or more matching elements.

### Asserting Text

`#text` is provided by Nokogiri to check the text of an element.

```ruby {4}
it "has the title in the H1" do
  result = generate_and_parse(described_class.new)

  expect(result.e!("h1").text).to eq("Welcome to the app!")
end
```

### Asserting Text Using I18N

If you don't want to hard-code text in your tests, you can use your I18n
Strings by using the `have_i18n_string` matcher. Given this fragment in
`app/config/i18n/en/2_app.rb`:

```ruby
# app/config/i18n/en/2_app.rb
{
  en: {
    cv: {
      # ...
    },
    pages: {
      HomePage: {
        title: "Welcome to the app!",
      }
    },
    # ...
  },
}
```

You can assert without hard-coding the string like so:

```ruby {4}
it "has the title in the H1" do
  result = generate_and_parse(described_class.new)

  expect(result.e!("h1")).to have_i18n_string("pages.HomePage.title")
end
```

### Asserting HTML Attributes

You can assert that an attribute is present via `have_html_attribute`

```ruby {4}
it "has an id on the title" do
  result = generate_and_parse(described_class.new)

  expect(result.e!("h1")).to have_html_attribute(:id)
end
```

You can also assert that the attribute has a specific value:

```ruby {4}
it "has an id on the title" do
  result = generate_and_parse(described_class.new)

  expect(result.e!("h1")).to have_html_attribute(id: "main-title")
end
```

## Asserting The Behavior of `before_generate`

Your page may implement `before_generate`, which can return a redirect or an
HTTP status instead of generating HTML.  If that happens and you've called
`generate_and_parse`, your test will error out.  Instead, call
`generate_result`.

### Asserting a Redirect

`have_redirected_to` can check if your page's `before_generate` did a redirect.

```ruby {4}
it "has redirects if not logged in" do
  result = generate_result(described_class.new)

  expect(result).to have_redirected_to(LoginPage)
end
```

### Asserting a 404 (or other HTTP Status)

`have_returned_http_status` can check if your page's `before_generate` return
an HTTP status only.

```ruby {4}
it "has does not exist if not logged in" do
  result = generate_result(described_class.new)

  expect(result).to have_returned_http_status(404)
end
```

## Creating a Page With Sessions and Other Request-Scoped Objects

If your page requires a session, a flash, or a clock, `Brut::SpecSupport::ComponentSupport` provides helper methods.

Given this page outline:

```ruby
class WidgetsPage < AppPage

  def initialize(session:, flash:, clock:)
    # ...
  end

  def page_template
    # ...
  end
end
```

To create an instance in a test, use `empty_session`, `empty_flash`, and
`real_clock`

```ruby {2-6}
it "has an id on the title" do
  page = described_class.new(
           session: empty_session,
           flash: empty_flash,
           clock: real_clock
         )
  result = generate_and_parse(page)

  expect(result.e!("h1")).to have_html_attribute(id: "main-title")
end
```

### Asserting Session Manipulation

Store `empty_session` in a variable, then assert. It'll be an instance of your
`AppSession`, so you can (and should) call its methods, instead of using `[]`.
Assuming your `AppSession` defined `#special_value`:

```ruby {2,4,10}
it "puts a value in the session" do
  session = empty_session
  page = described_class.new(
           session:,
           flash: empty_flash,
           clock: real_clock
         )
  result = generate_and_parse(page)

  expect(session.special_value).to eq("foo")
end
```

### Asserting the Flash

Store `empty_flash` in a variable, then assert. It'll be an instance of your
`Brut::FrontEnd::Flash`.

```ruby {2,5,10}
it "puts a notice in the flash" do
  flash = empty_flash
  page = described_class.new(
           session: empty_session,
           flash:,
           clock: real_clock
         )
  result = generate_and_parse(page)

  expect(flash.info).to eq(:updated_notification)
end
```

### Setting The Flash Before the Test

`empty_flash` returns a real `Brut::FrontEnd::Flash`, so you can manipulate it
before a test. You can also use `flash_from` to create a flash from a hash:

```ruby {2,10}
it "shows the flash notice" do
  flash = flash_from(notice: :updated_widget)

  page = described_class.new(
           session: empty_session,
           flash:,
           clock: real_clock
         )
  result = generate_and_parse(page)

  expect(result.e!("[role='status']").to have_i18n_string(:updated_widget)
end
```

### Manipulating Time 

Sometimes a page's behavior is based on the current time.  In that case, the
page should accept a `clock:`, and your test must provide it.  `real_clock`
uses the same clock that would be used in production, however `clock_at` and
`clock_in_timezone_at` can return a clock whose `now` returns a fixed value.

```ruby
it "uses dark mode at night" do
  clock = clock_at(now: "2025-01-01 20:30")

  result = generate_and_parse(described_class.new(clock:))

  expect(result.e!("body")).to have_html_attribute("data-dark")
end
```
