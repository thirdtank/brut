# Database Schema / Migrations

Brut provides access to the database via the [Sequel library](https://sequel.jeremyevans.net/).  To manage your database schema, Brut uses Sequel's facility for this, with some of its own enhancements.

> [!NOTE]
> Brut currently only supports Postgres. Sequel supports many database systems, however Brut's extensions are
> currently geared toward Postgres only.

## Overview

Your database schema is managed by a series of changes that build upon one another
called *migrations*.

For example, if you have a table `widgets` that has a `name` and `description`, to add a `status` field, you cannot `drop table widgets` and then `create table widgets(...)` with the fields. You must instead `alter table widgets(...)` to add the new column.

Thus, each migration file is a change to the schema produced by all previous migration files. 

Brut's provides this via Sequel. See [both](https://sequel.jeremyevans.net/rdoc/files/doc/schema_modification_rdoc.html) [docs](https://sequel.jeremyevans.net/rdoc/files/doc/migration_rdoc.html) for details on the API.  Any schema modification method Sequel documents is available, however some default behavior has changed.

### Creating Migrations

To create a migration, use `bin/db new-migration`. It accepts any  number of arguments that will be joined together to form the filename:

```
> bin/db new-migration user accounts
[ bin/db ] Migration created:
    app/src/back_end/data_models/migrations/20250508132646_user-accounts.rb
```

If you will be creating [database models](/database-access) as well, you may find it
easier to use `bin/scaffold db_model`, which will create an empty database model
class, empty test, and empty factory, along with an outline of your migration:

```
bin/scaffold db_model widget
[ bin/scaffold ] Executing ["bin/db new_migration create_widget"]
[ bin/db ] Migration created:
    app/src/back_end/data_models/migrations/20250712182257_create_widgets.rb
[ bin/scaffold ] ["bin/db new_migration create_widgets"] succeeded
[ bin/scaffold ] Creating DB::Foo in app/src/back_end/data_models/db/widget.rb
[ bin/scaffold ] Creating spec for DB::Foo in specs/back_end/data_models/db/widget.spec.rb
[ bin/scaffold ] Creating factory for DB::Foo in specs/factories/db/widget.factory.rb
```

> [!IMPORTANT]
> Brut doesn't do pluralization logic.  Although Sequel does do some, you should
> not refer to your database model plurally. If you were do run `bin/scaffold
> db_model widgets`, you'd create the class `DB::Widgets`, which would not work.
> Be aware.

Note that the files are located in `app/src/back_end/data_models/migrations` and
have a name prefixed with a timestamp.  This timestamp determins an ordering of how
the files are applied to the database.

The file is created mostly blank:

```ruby
Sequel.migration do
  up do
  end
end
```

> [!NOTE]
> Sequels' migration API is similar in concept to Rails', but differs
> significantly in specifics. Please consult Sequel's documentation and
> don't assume Railsism will work the same way.

Brut encourages only "up" migrations.  Since Brut treats your development database
as ephemeral, there is little value to managing "down" migrations.

This is why Sequel's `change` method is not included in the scaffolded code.  `change`, like Active Record's method of the same name, automagically creates both "up" and "down" migrations, but *only* if you use the DSL. If you use raw SQL, `change` doesn't work. By using only `up`, you won't have to worry about this.

Let's create an accounts table that has an email field, a `deactivated_at` timestamp, and a `created_at` timestamp:

```ruby
Sequel.migration do
  up do
    create_table :accounts,
      comment: "People or systems who can access this system" do

      column :email, :text, unique: true
      column :deactivated_at, :timestamptz, null: true

    end
  end
end
```

A few notes that aren't obvious without knowing about Brut's extensions:

* `comment:` is required. You must provide documentation about what table is for
* The table has a primary key named `id` of type `int` that is a serial.
* `created_at` is created by default, with time `timestamptz` (AKA `timestamp with time zone`, see [Space/Time Continuum](/space-time-continuum)).
* `email` is not null by default.  `deactivated_at` *is* null because it's specified as such.

To apply this migration use `bin/db migrate`

```
> bin/db migrate
```

### Managing Migrations

Sequel uses a special database table to understand which migrations have been run.  This table will exist in
production and prevent you from applying migrations twice or skipping a migration.

Note that managing a production database in this way requires knowledge of both your database system and the data
itself.  Brut can only provide so much to make this process manageable.  You should consult [Strong Migrations'
README](https://github.com/ankane/strong_migrations?tab=readme-ov-file) and learn it deeply. Although it's
targeted at Rails developers, the information here applies to any database management system.

### Brut Extensions and Changes in Sequel's Behavior

Brut includes the following standard plugins and extensions:

* [`pg_array`](https://sequel.jeremyevans.net/rdoc-plugins/files/lib/sequel/extensions/pg_array_rb.html)
* [`pg_json`](https://sequel.jeremyevans.net/rdoc-plugins/files/lib/sequel/extensions/pg_json_rb.html)
* [`table_select`](https://sequel.jeremyevans.net/rdoc-plugins/classes/Sequel/Plugins/TableSelect.html), which
changes queries to prepend `*` with the table name, e.g. `select accounts.*` instead of `select *`.
* [`skip_saving_columns`](https://sequel.jeremyevans.net/rdoc-plugins/classes/Sequel/Plugins/SkipSavingColumns.html) which will skip saving columns that the database generates.

Brut also provides the following plugins and behavior changes:

* `Sequel::Extensions::BrutInstrumentation`, which adds OpenTelemetry instrumentation to Sequel (see [Instrumentation](/instrumentation)).
* `Sequel::Plugins::FindBang`, which adds `find!` to all models. This wraps Sequel's `first!` method, but
provides a more helpful error message when no records are found
* `Sequel::Plugins::CreatedAt`, which automatically sets `created_at` when a record is created.
* `Sequel::Plugins::ExternalId`, which adds support for external IDs (see below)
* `Sequel::Extensions::BrutMigrations`, which enhances the migrations API (see below)

#### External IDs

It's often useful to provide a unique identifier for a record that is not the database primary key.  There are
many advantages to doing so, the main being that your primary and foreign keys are
considered private and for developer use only.  Creating additional externalizable
unique keys is trivial, so Brut provides a way to do that.

> [!NOTE]
> **Primary keys** and **keys** are not the same thing.  **Primary keys** are
> what is used to identify a record for the purposes of referential integrity.
> A **key** simply uniquely identifies a row or is a unique constraint on a table.
> Tables have only one primary key, but potentially many keys. Brut uses
> *synthetic* (sometimes called *surrogate*) keys as primary keys.  This means
> they have no business meaning and can be safely used for foreign keys
> and other cases without conflating them with domain concepts.


In Brut, an external ID is automatically generated by the database when a record is created.  By convention, it
is prefixed with a short string representing your app and a short string representing the table, followed by a
unique hash.

For example, if our app's prefix is, say, "my" (for "my app"), and the accounts table's prefix is "ac" (for "accounts"), an external ID might look like `myac_3457238947239487`.  This double-prefixing is extremely useful when sharing these values with the outside world.  You can immediately identify an ID from your app *and* know what sort of thing it refers to.

To use external IDs in Brut, you must do three things:

1. You must set your external ID prefix in `app/src/app.rb`. This should have been done when you created your
   Brut app, but it looks like so:

   ```ruby {5}
   class App < Brut::App
     # ...
     def initialize
       # ...
       Brut.container.override("external_id_prefix","my")
     end
    
     # ...
   end
   ```
2. When creating the table in a migration, use `external_id: true`:
   ```ruby {5}
   Sequel.migration do
     up do
       create_table :accounts,
         comment: "People or systems who can access this system",
         external_id: true do

         column :email, :text, unique: true
         column :deactivated_at, :timestamptz, null: true

       end
     end
   end
   ```
3. In your [data model class](/database-access), use `has_external_id` to specify the prefix for this table:

   ```
   class DB::Account < AppDataModel
     has_external_id :ac

     # ...
   end
   ```

Brut creates the external ID using Ruby code as part of Sequel's lifecycle hooks.  It's only set a) on creation, and b) if there is no value provided when creating the record.

This means that you can set values explicitly if you like, *and* you can change them later.  This is useful if you shared the value with someone you didn't mean to.  Because these external IDs aren't use for referential integrity/foreign keys, they can be changed at any time, as long as the value is unique (which will be enforced by the database).

### Brut Migration Changes and Enhancement

Brut attempts to set default behavior for migrations to encourage a modicum of best practices.  These are:

* **Automatic synthetic primary key named `id` of type `int`.**  You almost always want this. You can change the
primary key configuration per table if you like, but if you do nothing, you get a primary key that works for 99%
of your needs.
* **Automatic `created_at` of type `timestamptz`.** It's a good practice to store the date a record was created. This can help with debugging and provide a reliable sort key for data that otherwise has none.  It uses `timestamp with time zone`, which you are encouraged to use always. See [Space/Time Continuum](/space-time-continuum) for details.
* **No automatic `updated_at`.** While you are free to add `updated_at`, in practice this column creates more problems than it solves.  If you need to know when data has changed, it is almost always better to do this with an audit table, event log, or special-purpose field.
* **`create_table` requires `comment:`.** Just document your tables.  It takes two seconds and can save a lot of
time later.
* **Support for external IDs via `external_id:`.** As discussed above, this will create a unique `external_id`
column on your table and ensure it has a value on creation.
* **Columns are `NOT NULL` by default.** Null is not a valid value.  In many cases, your columns should not allow
`NULL` (`nil`), so in Brut apps, you must opt into nullable columns. You can use `null: true` to make a column
nullable.
* **Foreign keys are `NOT NULL` and have an index created for them by default.** Foreign keys should rarely be
`NULL` and you almost always want an index on them, since you are likely to using them in queries, e.g.
`account.widgets` would join on `accounts.widget_id`.  You can opt out of either via `null: true` and `index:
false`.
* **The method `key` allows you to specify a non-primary key, AKA a unique index**.  Suppose our `accounts` table
allowed duplicate email addresses, but only one per `organization_id`. You'd model this by creating a unique
index on `(email,organization_id)`.  In Brut:
  ```ruby {11}
  Sequel.migration do
    up do
      create_table :accounts,
        comment: "People or systems who can access this system",
        external_id: true do

        column :email, :text, unique: true
        foreign_key :organization_id, :organizations
        column :deactivated_at, :timestamptz, null: true

        key [:email, :organization_id]

      end
    end
  end
  ```

  This allows your migrations to be more expressive *and* make it easier to set up unique constraints that relate
  to your business logic or domain.

## Testing

Generally, you don't test database migrations, however you may want to test constraints or other logic you have
set up.  Techniques for doing this are in the [database access](/database-access#testing) section.

## Recommended Practices

### Ephemeral Dev Database

Brut intends for your develompent database to be ephemeral.  Your entire workflow should be built around it
being OK and normal to completely blow away your development database and recreate it.  This is why down
migrations (and the  use of `change`) are discouraged. You really don't need them.

Assuming you have [seed data](/seed-data) set up properly, you can reliably reset everything like so:

```
> bin/db rebuild
> bin/db seed
> bin/db rebuild -e test
```

As long as you don't change migrations that have been applied in production, you can safely run the above
commands to iterate on a schema change.

This does imply that you should not run business logic or make *data* changes in your migration files.  No migration
should rely on specific data being in the database.

This workflow my be much different from what you are used to, but you will be quite happy when you adopt it.  The days
of downloading a carefully-curated database image and taking great care to never delete it are over.

### Use Your Database, It is Awesome

Your database is the only part of the system that has any chance of ensuring data integrity.  You can use
constraints, types, foreign keys, etc. to ensure that the data in your database is correct, based on your current
understandings.  Code-based validation systems **cannot achieve this on any level**.

Thus, you are encouraged to learn about your database's features and use them!

For example, here's a way to add full text search to an existing table in Postgres:

```ruby
add_column :full_text_search,
  :tsvector,
  generated_always_as: Sequel.lit(%{
    (
      setweight(to_tsvector('english', name),'A') ||
      setweight(to_tsvector('english', coalesce(description,'')),'B')
    )
  }),
  generated_type: :stored
```

If you are using Postgtes, why *not* use its features?  Unless your app is database-agnostic, you should be using
the features of your database, even if they aren't explicitly exposed via Sequel's Ruby API (that's why `Sequel.lit` exists).

## Technical Notes

> [!IMPORTANT]
> Technical Notes are for deeper understanding and debugging. While we will try to keep them up-to-date with changes to Brut's
> internals, the source code is always more correct.

_Last Updated May 8, 2025_

As mentioned, Brut uses Sequel under the covers.  This is unlikely to change.

As also mentioned, Brut's extensions often rely on Postgres.  While we can all dream of a world where every
developer uses the same database server, we don't live in that world.  Brut should, some day, support all the
databases that Sequel supports.  For now, however, it only supports Postgres.

This hard-coded support is due to:

* `pg_array`
* `pg_json`
* Reliance on `citext` and `comment`
* Reliance on `timestamptz`

Brut is likely to add more Postgres-specific features before adding support for other databases.
