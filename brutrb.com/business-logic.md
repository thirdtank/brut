# Business or Domain Logic

Since business and domain logic is not required, nor encouraged, to go in your data models, where does it go?

It can go anywhere you like - Brut is not currently prescriptive.

## Overview

It's recommended that you place classes in `app/src/back_end`.  Any directory created in there will be
auto-loaded by Brut/Zeitwerk based on its rules.  This means that classes in any directory in `app/src/back_end`
should not be namespaced.

For example, if you have *commands* and *queries*, you may want them in `app/src/back_end/commands` and
`app/src/back_end/queries`, respectively.  In this case, `NewOrganizationCommand` would go in
`app/src/back_end/commands/new_organization_command.rb` and `AccountQuery` would go in
`app/src/back_end/queries/account_query.rb`

Or, you could could organize them into `app/src/back_end/business_logic/commands` and `app/src/back_end/business_logic/queries`.  In that case, `Commands::NewOrganization` would be expected in `app/src/back_end/business_logic/commands/new_organization.rb` and `Queries::Account` would be expected in `app/src/back_end/business_logic/queries/account.rb`.

How you organize it is up to you.

## Testing

Tests can be written using RSpec in the usual way.  Spec files should be in
`specs/back_end/path/to/class.spec.rb`.  Note that Brut expects Spec files to end in `.spec.rb` and *not*
`_spec.rb`.

There is nothing special about the tests for your domain logic. Write them however you need to.

## Recomended Practices

This could be an entire series of books.  The main recommendation is to take a light approach and don't
immediately install complex frameworks or libraries unless you know you need them.

Something somewhere in your business logic will need to interface with your front-end.  The simplest way to do
that is to allow form objects to be passed into your back-end.  The second simplest way is to pass form values
into your back-end.

You are strongly discouraged from having your front-end locate data models and pass those to your back-end.  This
can be done while prototyping and for fast iteration on a concept, but generally you do not want to query your
database from your handlers or pages just to pass the results into a back-end class.

Exposing data models to the front-end is generally OK, as that is sometimes what you need to do.

## Technical Notes

> [!IMPORTANT]
> Technical Notes are for deeper understanding and debugging. While we will try to keep them up-to-date with changes to Brut's
> internals, the source code is always more correct.

_Last Updated May 7, 2025_

Creating universal abstractions from business logic is difficult. Brut is unlikely to do this. If it does, it
will be after much analysis of exsiting patterns and *only* if it helps avoid mistakes and increases developer
throughput.
