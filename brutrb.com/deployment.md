# Deployment

Brut apps are Rack apps, so they can be deployed in conventional
ways.   Brut apps are 12-factor apps and the scripts used for
development are inteded to work for production as well.

## Overview

Everyone deploys apps in different ways.  Brut can't provide a
simple solution for all deployment setups, so this document will
outline considerations when setting up deployment.

The most direct way to understand what needs to happen is to look
at `deploy/Dockerfile`, which is the foundation of a `Dockerfile`
you can use.  In particular, it shows you the commands needed to
setup and run the app in production:

Beyond installing system software to run any Ruby web app, as well
as whatever is needed for NodeJS and Postgres, the Brut-specific
parts look like so:

1. Install Ruby Gems with `bundle install`
2. Install Node modules with `npm clean-install`
3. Build all assets with `bin/build-assets` (this will bundle all
   CSS and Javascript, plus copy over any other [assets](/assets)
   to the locations from where the Brut app will serve them)
4. Run the app with `bin/run`

Your Brut app also includes `bin/release` which is a script
intended to run in the production environment after the code has
been deployed, but before the app starts up.  By default, it
applies any needed migrations to the database.

## Testing

If you are using Docker, you can create the `Dockerfile`s and run
them locally to see how they work.  You will need to have local
versions of all infrastructure (database, Redis, etc.), but if
these work locally, there is a high chance they work in
production.

If you are not using Docker, you will need to apply various
techniques that are beyond the scope of this documentation.

## Recommended Practices

Brut goes to great lengths to avoid environment-specific code.
Much of Brut's behavior works the same in dev as it does in
production. For example, assets are hashed in all environments.

Assuming your code does the same thing, there should be a minium
of surprises.  That all being said, here are some recommendations:

* Create a way to interact with external services in a testing
capacity. For example, ensure you have a test user with a known
email address and trigger an email to them.  Or a company credit
card you charge and refund.
* Configure observability so you know what your app is doing at
all times.
* Configure a URL that, when accessed, produces an error. This
allows you to check your error reporting system.
* Create a page somewhere that shows the git SHA of your
deployment, or some other unique, unambiguous version number. This
will clarify what version of the code is actually running.


