# Testing a Handler

Brut classes can be created and tested somewhat conventionally, however there
are convienience methods to make testing a bit easier.

## Call `handle!`, not `handle`

`handle` is the method you implement, but Brut will call `handle!`, which it
implements to call your `handle` implementation.  Your tests should call
`handle!`.

## Testing a Redirect

To test that a redirect happened, use `have_redirected_to`:

```ruby {10}
it "redirects to the PreferencesPage when there are no constraint violations" do
  form    = UserPreferencesForm.new(params: {
              account_name: "My Account",
              default_num_tasks: 10,
            })
  handler = described_class.new(form:)

  result = handler.handle!

  expect(result).to have_redirected_to(PreferencesPage)
end
```

## Testing a Page is Re-Rendered

When a form has constraint violations, you usually want to re-generate
(re-render) an HTML page with that form.  To test that, use `have_generated`:

```ruby {7}
it "re-generates PreferencesPage when there are client-side constraint violations" do
  form    = UserPreferencesForm.new(params: {})
  handler = described_class.new(form:)

  result = handler.handle!

  expect(result).to have_generated(PreferencesPage)
end
```

## Testing for Constraint Violations/Validation Errors

The `have_constraint_violation` matcher can test this against your form, *after* you call `handle!`  

```ruby {7,8}
it "re-generates PreferencesPage when there are client-side constraint violations" do
  form    = UserPreferencesForm.new(params: {})
  handler = described_class.new(form:)

  result = handler.handle!

  expect(form).to have_constraint_violation(:default_num_tasks,
                                            key: :required)
end
```
