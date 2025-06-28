# Authentication Example

It's impossible to account for all types of authentication you may want to use, but
this recipe will demonstrate all the moving parts:

* How to require authentication for some pages
* How to design pages that require authentication
* How to manage the signed-in user in code

## Feature Description

* Visitors can sign up for an account with an email and password
* Visitors can log in with their email and password
* Visitors cannot access the home page without logging in
* Visitors can access the about page without logging in

## Recipe

First, we'll make a database table called `accounts` that will have an email field
and a password hash field.

```
bin/db new-migration accounts
```

This will create a file in `app/src/back_end/data_models/migrations` 
