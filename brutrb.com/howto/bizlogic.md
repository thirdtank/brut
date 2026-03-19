# Managing Business Logic

Brut doesn't prescribe any way to manage your business logic, but it has a few recommendations:

* Business Logic does not go in `app/src/back_end/data_models`.  Unlike Rails, you are explicitly discouraged from putting business logic in your database models. You can, but you should not.
* Pick a strategy and create directories in `app/src/back_end/`
* Do not go to great lengths to abstract Brut away from your business logic. You are using Brut, so it's logical that your business logic interacts wiht Brut-provided classes. 
* Choose a strategy that your team can easily follow and succeed at.  A theoretically pure system design is pointless if your team can't build it.

Here are three strategies you can try if you don't know how to get started

## *Domain Model* Strategy

Here, you create a *domain model* in `app/src/back_end/domain`. For example,
you might have an `Account` class that manages accounts.  Its methods map to
operations that logically go with an account, and these operations may or may
not operate on a `DB::Account`.

```ruby
# app/src/back_end/domain/account.rb
class Account
  def self.find!(id:)
    self.new(db_account: DB::Account.find!(external_id: id)
  end

  def self.login(email:, password:)
    db_account = DB::Account.find(email:)
    if db_account
      if db_account.hashed_password = hash(password)
        return self.new(db_account:)
      end
    end
    NoAccount.new
  end

  def initialize(db_account:)
    @db_account = db_account
  end
end

# app/src/back_end/domain/no_account.rb
class NoAccount
end
```

This strategyh can be quite complicated and difficult to achieve, however it
can also result in a fluent, easy-to-follow API if the design is done well.

## *Service Layer* Strategy

Here, you create classes in `app/src/back_end/services` that model explicit
processes or workflows your app needs.  These service classes may have only one
method in them, or they could have several cohesive methods.

Classes tend to model a process rather than data, and the methods on these
classes tend to be stateless or more functional

```ruby
# app/src/back_end/services/login.rb
class Login
  def login(email:, password:)
    db_account = DB::Account.find(email:)
    if db_account
      if db_account.hashed_password = hash(password)
        return db_account
      end
    end
    nil
  end
end
```

A service layer is much easier to model at the start, since you can map your
user flows and requirements directly to methods.  As your app grows in
complexity, you will need to factor out re-usable code and create namespaces to
manage the many methods you will need.

## *Command/Query Separation* Strategy

In this strategy, all of your business logic is divided into either *queries*, which locate data, or *commands*, which perform actions.  You'd create `app/src/back_end/commands` and `app/src/back_end/queries` to store the types of classes, and would want to suffix them with `*Command` or `*Query`, respectively.

```ruby
# app/src/back_end/queries/account_query.rb
class AccountQuery
  def find_by_email(email:)
    DB::Account.find(email:)
  end
end

# app/src/back_end/commands/login_command.rb
class LoginCommand
  def login(db_account:, password:)
    db_account.hashed_password = hash(password)
  end
end

# example usage, e.g. in a Handler
db_account = AccountQuery.new.find_by_email(email: @form.email)
if LoginCommand.new.login(db_account:, password: @form.password)
  session.logged_in!
else
  @form.server_side_constraint_violation(input_name: :email,
                                         key: :no_such_account)
  LoginPage.new(@form)
end
```

Command/Query separation can be a bit less messy than Service Layer, but easier
to design than a Domain Model.  You'd still need a way to manage re-use as the
app grows larger, and you may eventually need classes to orchestrate your
commands and queries.  This orchestration layer could be a service layer, or
simply exist in your handlers and pages.

## *A Little Bit of Everything* Strategy

You don't have to be regimented in your approach.  You may find that a server layer at the seam of your business logic, orchestrating commands and queries, which themselves use domain objects, makes sense.

Just make sure you have a clear definition of what you are doing, how you are
doing it, and a cadence for re-evaluating.  End-to-end tests can help with
major changes to your business logic organization.
