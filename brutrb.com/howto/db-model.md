# Create a Data Model/Database Table

In Brut, you can create database tables without creating data models to access
them, but you usually want both.  There are two steps:

1. Create a migration to create the database table(s)
2. Use `brut scaffold` to create the Sequel database model and related classes

## Create a Database Table

First, create a new migration:

```
dx/exec brut db new_migration widgets-table
```

This will create a file in `app/src/back_end/data_models/migrations`.  It's
filename will have a timestamp in it.

Let's suppose our new `WIDGETS` table will have a unique name, a quantity, an
availability date and an optional archive timestamp.  This is how you'd create
the migration (keeping in mind the filename depends on the date you ran `brut db new_migration`):

```ruby {3-15}
Sequel.migration do
  up do
    create_table :widgets,
                 comment: "Widgets that are, will be, or were for sale",
                 external_id: true do
      column :name,         :text, unique: true
      column :quantity,     :integer
      column :available_on, :date
      column :archived_at,  :timestamptz, null: true

      constraint(
        :quantity_must_not_be_negative,
        "quantity >= 0"
      )
    end
  end
end
```

Columns are `NOT NULL` by default, so only `archived_at` needs to specify if
`NULL` is allowed.  Note also that we use a constraint to ensure `quantity` is
not negative.  Finally note that Brut will add `created_at` to the table and
set it when a row is created.

Note that `external_id: true` is not required, but is recommended if you will
need to expose a unique ID for a record externally.  Brut will manage this
value for you.

## Create A Class to Access the Database

In Brut, a class that accesses a database table is called a *data model*, since
it models the database table (and not anything else).  When you create a data
model, you also want to create a factory for use in tests that will make valid
instances of the data model.

This can all be done via `brut scaffold db_model`

```bash
dx/exec brut scaffold db_model Widget
```

This will create `app/src/back_end/data_models/db/widget.rb`, `spec/back_end/data_models/db/widget.spec.rb` and `spec/factories/db/widget.factory.rb`

All these files will be empty.  You must edit `widget.factory.rb` so it creates
valid data.

## Filling in the Factory

While `db/widget.rb` can discern its columns from the database,
`widget.factory.rb` needs to be given test data.  Brut includes the Faker
gem, and you can use this to create unique and/or random data.

```ruby {4-10}
# specs/factories/db/widget.factory.rb
FactoryBot.define do
  factory :widget, class: "DB::Widget" do
    name         { Faker::Lorem.words.unique }
    quantity     { Faker::Number.within(range: 1..100).to_i }
    available_on { Date.today }

    trait :archived do
      archived_at { Time.now }
    end
  end
end
```

You can check that the factory is valid via `brut test run`

```
dx/exec brut test run specs/lint_factories.spec.rb
```

Factories must always be creatable in the database.
