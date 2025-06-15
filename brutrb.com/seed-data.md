# See Data for Development

In Brut, *seed data* is data you set up for the purposes of doing local development.  It is *not* for managing
production data and is not used for tests.

## Overview

Seed data lives in `app/src/back_end/data_models/seed`.  You can create as many files in here as you like. Each
should contain a class that extends `Brut::BackEnd::SeedData` and implements `seed!`.  By doing this, the class
is regsitered with Brut and when you run `bin/db seed` all the classes are created and `seed!` is called.

FactoryBot will be set up for you, so you can call `FactoryBot.create` to create the data.

For example, here is how we might create two accounts, one deactivated, in the same organization:

```ruby
# app/src/back_end/data_models/seed/all_seed_data.rb
class AllSeedData < Brut::BackEnd::SeedData
  include FactoryBot::Syntax::Methods

  def seed!
    organization     = create(:organization)
    active_account   = create(:account,
                              organization:,
                              email: "pat@example.com")
    inactive_account = create(:account, :inactive,
                              organization:,
                              email: "chris@example.com")
  end
end
```

You can store other data here, such as a CSV, if you want to load data organized in another way.  Seed data will
only ever be loaded in development, so you can organize it however you like.

## Testing

You do not need to test your seed data. Presumably, you will be using your app in development, and this will be
sufficient to determine if your seed data is fit for purpose.

## Recommended Practices

* Use FactoryBot as this is consistent with your tests
* Use literal values for anything relevant to local development. In the example above, the two email addresses are important, presumably because you'd be using those to login. The organization name, however, is irrelevant, so we allow Faker to come up with a name.
* Use local variables as documentation. In the example above, there's no need to set `active_account` or
`inactive_account`, but doing so makes it clear what those objects are for.
* Ensure all seed data classes are independent from one another, as the order of their exeuction cannot be guaranteed.

## Technical Notes

> [!IMPORTANT]
> Technical Notes are for deeper understanding and debugging. While we will try to keep them up-to-date with changes to Brut's
> internals, the source code is always more correct.

_Last Updated May 8, 2025_

All seed data is loaded in one transaction.  This means that if any class' seed data fails, no data will be
written.

Seed data also is not assumed to be idempotent. If you run it twice, you will likely get an error.  Because 
[your dev database is ephemeral](/database-schema#ephemeral-dev-database), you can always recreate your dev
database via `bin/db rebuild && bin/db seed`.

