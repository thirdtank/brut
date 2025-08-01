# Migration Example

If you've not used [Sequel](https://sequel.jeremyevans.net/) before, this recipe will show you the basics of creating [migrations](https://sequel.jeremyevans.net/rdoc/files/doc/migration_rdoc.html),
which are how the database schema is managed in Brut.

## Feature

* An accounts table will store an email and a deactivated date
* A blog posts table will store a title and content, and be attributed to an
account.

## Recipe

We'll create the migration, create data models, create and lint factories, then create seed data.

### Create the Migration

Create the migration file with `bin/db new_migration`:

```
> bin/db new_migration Accounts and Blog Posts
[ bin/db ] Migration created:
   app/src/back_end/data_models/migrations/20250711215310_Accounts-and-Blog-Posts.rb
```

> [!NOTE]
> Your filename will be different, since it embeds a timestamp for when `bin/db new_migration` was run.

Now, use Sequel's migrations API, keeping in mind [Brut's augmentations](/database-schema), to create our tables.

Our tables will use [an external ids](/database-schema#external-ids).  Note that
Brut will ensure both tables have primary keys and have `created_at` fields.

```ruby
# app/src/back_end/data_models/migrations/20250711215310_Accounts-and-Blog-Posts.rb
Sequel.migration do
  up do
    create_table :accounts,
                  comment: "People or systems who can access this system",
                  external_id: true do

      column :email,          :text, unique: true
      column :deactivated_at, :timestamptz, null: true

    end
    
    create_table :blog_posts,
                  comment: "Posts on our amazing blog",
                  external_id: true do

      column :title, :text
      column :content, :text

      foreign_key :account_id, :accounts
    end
  end
end
```

You can apply this migration with `bin/db migrate`:

```
bin/db migrate
```

> [!IMPORTANT]
> This only applied migrations to the dev database.  `bin/ci` and `bin/test e2e`
> will apply them to the test database, but you may need to do it yourself via
> `bin/db migration -e test`

> [!NOTE]
> There is no down migration. If you need to change and re-apply this before
> you have promoted it to production, rebuild your dev database with `bin/db
> rebuild`.  It will apply all migrations from a fresh, empty database.

You can examine the tables with `psql`, via `bin/dbconsole`:

```
> bin/dbconsole
development=# \d accounts
                                       Table "public.accounts"
     Column     |           Type           | Collation | Nullable |             Default              
----------------+--------------------------+-----------+----------+----------------------------------
 id             | integer                  |           | not null | generated by default as identity
 email          | text                     |           | not null | 
 deactivated_at | timestamp with time zone |           |          | 
 created_at     | timestamp with time zone |           | not null | 
 external_id    | citext                   |           | not null | 
Indexes:
    "accounts_pkey" PRIMARY KEY, btree (id)
    "accounts_email_key" UNIQUE CONSTRAINT, btree (email)
    "accounts_external_id_key" UNIQUE CONSTRAINT, btree (external_id)
Referenced by:
    TABLE "blog_posts" CONSTRAINT "blog_posts_account_id_fkey" FOREIGN KEY (account_id) REFERENCES accounts(id)

development=# \d blog_posts
                                    Table "public.blog_posts"
   Column    |           Type           | Collation | Nullable |             Default              
-------------+--------------------------+-----------+----------+----------------------------------
 id          | integer                  |           | not null | generated by default as identity
 title       | text                     |           | not null | 
 content     | text                     |           | not null | 
 account_id  | integer                  |           | not null | 
 created_at  | timestamp with time zone |           | not null | 
 external_id | citext                   |           | not null | 
Indexes:
    "blog_posts_pkey" PRIMARY KEY, btree (id)
    "blog_posts_account_id_index" btree (account_id)
    "blog_posts_external_id_key" UNIQUE CONSTRAINT, btree (external_id)
Foreign-key constraints:
    "blog_posts_account_id_fkey" FOREIGN KEY (account_id) REFERENCES accounts(id)
```

Note that all columns are `NOT NULL` except `deactivated_at`, which we explicitly
set as nullable.  Note that the foreign key on `account_id` has an index and is
non-nullable.  And note that both tables have `external_id` and `created_at`
columns. Brut will manage their contents.

### Create Data Models

Brut doesn't create your data models for you, since it assumes you prefer writing
code in your editor and not on the command line.  Your data models will initially be
pretty short.

```ruby
# app/src/back_end/data_models/db/account.rb
class DB::Account < AppDataModel
  has_external_id :ac
  one_to_many :blog_posts
end

# app/src/back_end/data_models/db/blog_post.rb
class DB::BlogPost < AppDataModel
  many_to_one :account
end
```

You can run `bin/console` to try to test these, but it's easier to create factories
and use the `specs/lint_factories.spec.rb` to do that for us.

### Create Factories

Factories go in `specs/factories/db` and have a `.factory.db` suffix:

```ruby
# specs/factories/db/account.factory.rb
FactoryBot.define do
  factory :account, class: "DB::Account" do
    email         { Faker::Internet.unique.email }

    trait :inactive do
      deactivated_at { Time.now }
    end
  end
end

# specs/factories/db/blog_post.factory.rb
FactoryBot.define do
  factory :blog_post, class: "DB::BlogPost" do
    title { Faker::Lorem.sentence }
    content { Faker::Lorem.paragraphs.join("\n\n") }

    account
  end
end
```

Note that the blog post factory creates an account.  This is so that
`create(:blog_post)` will always succeeed in creating valid data.

To prove it, we'll lint our factories:

```
bin/test run specs/lint_factories.spec.rb
```

This will create every combination of every factory and fail if doing so raises an
error.

### Create Seed Data

Now, we'll set up seed data.  `mkbrut` should've created
`app/src/back_end/data_models/seed/seed_data.rb`, so we'll use that.

```ruby
require "brut/back_end/seed_data"
class SeedData < Brut::BackEnd::SeedData
  include FactoryBot::Syntax::Methods
  def seed!
    pat   = create(:account,            email: "pat@example.com")
    chris = create(:account, :inactive, email: "chris@example.com")

    5.times do
      create(:blog_post, account: pat)
      create(:blog_post, account: chris)
    end
  end
end
```

We can apply this with `bin/db seed`:

```
bin/db seed
```

> [!IMPORTANT]
> `bin/db rebuild` will *not* apply seed data, however `bin/setup` should.
> For now, if you want to totally reset your database, you will need to do `bin/db
> rebuild && bin/db seed && bin/db rebuild -e test`
