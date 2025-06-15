# Database Access / Data Models

Brut provides access to the database via the [Sequel library](https://sequel.jeremyevans.net/).  Sequel is fully featured and provides a lot of ways of interacting with and managing your database.  Brut includes several plugins and extensions to provide opinionated default behavior or additional features.

One thing to keep in mind is that Brut refers to your database layer as *database models* (notably not the un-qualified "models").  Brut treats this layer as a *model* of your database, not a model of your *domain* (though you are free to conflate the two).

This section details how to access data in your database.

> [!NOTE]
> Brut currently only supports Postgres. Sequel supports many database systems, however Brut's extensions are
> currently geared toward Postgres only.

## Overview

Accessing your database in Brut uses Sequel's `Sequel::Model`.  A base class called `AppDataModel` exists in your
app from which all other data models extend:

```ruby
# app/src/back_end/data_models/app_data_model.rb
AppDataModel = Class.new(Sequel::Model)
class AppDataModel
  # You can insert your own shared methods here
end

# app/src/back_end/data_models/db/account.rb
class DB::Account < AppDataModel
end
```

All data models are in the `DB` namespace.  This clearly identifies a model as a model of your database and
not your domain.

Inside a data model, you can use all of Sequel's API. In particular, you will want to use its API for
[associations](https://sequel.jeremyevans.net/rdoc/files/doc/association_basics_rdoc.html) so that you can create
relationships between models.

In your business logic or front-end code, you can access your data using these models:

```ruby
account = DB::Account.find(email: form.email)
```

> [!IMPORTANT]
> Sequel's `Sequel::Model` is different from Active Record, especially when it comes to associations.
> `account.organizations` would return an `Array` of `DB::Organization` records, all fetched from the database.
> `account.organizations_dataset` would return a active-relation style object to allow stacking
> quieries.  **Please** familiarize yourself with Sequel's API.

## Testing

Testing, as it applies to data models, is made up of two parts: managing test *data* and testing the models
themselves.

### Test Data is Managed with FactoryBot

Brut apps come with [FactoryBot](https://github.com/thoughtbot/factory_bot) installed, and this is how you should
create test (and seed) data.

Factories for data models live in `specs/factories/db`. Because data models are in the `DB` namespace, you will
need to explicitly state the `class:` in the factory, but otherwise, you can use FactoryBot in a conventional
way. [Faker](https://github.com/faker-ruby/faker) is also installed to allow you to create realistic and
randomized data.

Here is a factory for our hypothetical account:

```ruby
# specs/factories/db/account.factory.rb
FactoryBot.define do
  factory :account, class: "DB::Account" do
    email         { Faker::Internet.unique.email }
    organization

    trait :inactive do
      deactivated_at { Time.now }
    end
  end
end
```

The `spec_support.rb` file generated when you created your Brut app should ensure that `FactoryBot::Syntax::Methods` is included in all specs, meaning you can do `create(:account)` to create an instance of `DB::Account`.

See [Unit Tests](/unit-tests) for more details on testing and Factory Bot setup.

### Testing Your Data Models

In general, you don't want to test the configuration in your data models. For example, testing that
`account.organization = organization` works is largely pointless, since this is provided by Sequel.

That said, if you have complex or unusual database constraints, having a test for them can be valuable.

Suppose our `DB::Account` has the following check constraint that requires an email end with `@example.com`:

```ruby {13-16}
Sequel.migration do
  up do
    create_table :accounts,
      comment: "People or systems who can access this system",
      external_id: true do

      column :email, :text, unique: true
      foreign_key :organization_id, :organizations
      column :deactivated_at, :timestamptz, null: true

      key [:email, :organization_id]

      constraint(
        :email_must_be_domain,
        "email ~* '@example.com$'"
      )
    end
  end
end
```

To test this, you would try to write invalid data into the database an ensure the expected exception is raised:

```ruby {11}
# specs/back_end/data_models/db/account.spec.rb
require "spec_helper"
RSpec.describe DB::Account do
  describe "email" do
    it "must end in @example.com" do
      expect {
        DB::Account.create(
          email: "pat@example.net",
          organization: create(:organization)
        )
      }.to raise_error(Sequel::CheckConstraintViolation)
    end
  end
end
```

If you don't want to be overly coupled to Sequel's exceptions, you can also assert on the message Postgres will
produce, which would include the name of the violated constraint:

```ruby {11}
# specs/back_end/data_models/db/account.spec.rb
require "spec_helper"
RSpec.describe DB::Account do
  describe "email" do
    it "must end in @example.com" do
      expect {
        DB::Account.create(
          email: "pat@example.net",
          organization: create(:organization)
        )
      }.to raise_error(/email_must_be_domain/)           
    end
  end
end
```

## Recommended Practices

### Do Not Put Business Logic On Your Database Models

There's no reason to, or benefit to doing so.  What you'll find is that any app of even moderate complexity will
not have a strict mapping from page to business concept to database table.  Rather these things will all differ
greatly, and each serves a different purpose.

The job of your data models—and the tables they provide access to—is to store reliable and unambiguous data.
Their job is to ensure there is no bad data such that when you ask the database a question, you get a reliable
and correct answer.

Your views and business logic do not have this exact same job.

As such, your models should only contain:

* configuration to allow navigating the database.
* methods to manage type conversions between your types and the strings or numbers required in the database
* methods to query the data based on data definitions (not business logic).

Business logic and data models *do* overlap at times, so there is some judgement in maintaining a clear
separation of concerns.  One way to manage this is to always put all logic elsewhere until you see a pattern of
re-use that leads you to extract that logic to a data model.

### Do Not Use Validations on Models Unless There is No Other Choice

Sequel provides a validation layer for use on models.  You should not generally use this, since a) data integrity
is baked into your database design, and b) user interactions and constraints are part of the front-end.

That said, there are times when you have data constraints that cannot be modeled in the database.  In that case,
a validation on the data model is better than nothing.  Since all data access for your app should go through your
data models, a validation on a data model has a high chance of being checked.

> [!NOTE]
> Since any process, app, or tool can manipulate your database, model-based validations won't be 
> in effect, and therefore won't be applied.  This is why you design your schema to avoid invalid
> data wherever possible.


## Technical Notes

> [!IMPORTANT]
> Technical Notes are for deeper understanding and debugging. While we will try to keep them up-to-date with changes to Brut's
> internals, the source code is always more correct.

_Last Updated May 8, 2025_

None at this time
