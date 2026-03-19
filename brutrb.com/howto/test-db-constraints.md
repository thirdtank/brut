# Testing Database Constraints

You don't need to test every constraint in your database, but it's handy to be
able to do it at times, since some constraints can be tricky to come up with.

The basic technique is to create a row in the database and check that the
constraint name shows up in the exception message.

Suppose our `accounts` table has an `opted_in_at` timestamp and an
`opted_out_at` timestamp.  You can't opt out if you have not first opted in, so
we create this constraint:

```
constraint(
  :must_be_opted_in_to_opt_out,
  %{
    (opted_in_at IS     NULL AND opted_out_at IS NULL) OR
    (opted_in_at IS NOT NULL)
  }
)
```

While you might be able to eyeball this as correct, you can be sure by testing
it in the test for `DB::Accounts`.

Here, we check all four cases. For the three that are allowed, we use RSpec's
`expect { ... }.not_to raise_error` construct.  For the fourth case, which the
constraint should not allow, we use `expect { ... }.to raise_error(..)` and
give it a regular expression containing the string name of our constraint.

```ruby {7,12,17,22}
# specs/back_end/data_models/db/accounts.spec.rb
RSpec.describe DB::Account do
  describe "must_be_opted_in_to_opt_out" do
    it "may be not opted in and not opted out" do
      expect {
        DB::Account.create(opted_in_at: nil, opted_out_at: nil)
      }.not_to raise_error
    end
    it "may be opted in and not opted out" do
      expect {
        DB::Account.create(opted_in_at: Time.now, opted_out_at: nil)
      }.not_to raise_error
    end
    it "may be opted in and opted out" do
      expect {
        DB::Account.create(opted_in_at: Time.now, opted_out_at: Time.now)
      }.not_to raise_error
    end
    it "may not be not opted in but opted out" do
      expect {
        DB::Account.create(opted_in_at: nil, opted_out_at: Time.now)
      }.to raise_error(/must_be_opted_in_to_opt_out/)
    end
  end
end
```

This will give us confidence that the error raised by `DB::Account.create` is
due to the constraint we are testing and not something else.
