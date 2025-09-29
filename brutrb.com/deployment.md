# Deployment

Brut apps are Rack apps, so they can be deployed in conventional
ways.

## Overview

There are just too many ways to deploy.  Brut attempts to address this by adhering to [12-factor principles](https://12factor.net).  Brut also tries not to create artifacts like `Procfile` or `Dockerfile` that would conflict with the artifacts you'd need to manage deployment.

That said, Brut includes first-class support for deploying to Heroku using containers.  More options will be included as necessary, either through direct support in code/tooling, or documentation here.

### Heroku Container-based Deployment

When creating your Brut app with `mkbrut`, the Heroku segment can be used to create files and scripts for a [Heroku container-based deployment](https://devcenter.heroku.com/articles/container-registry-and-runtime).

| File | Purpose | Notes |
|------|---------|-------|
| `bin/deploy` | Script to use to perform the deployment | This wraps `HerokuContainerBasedDeploy` in `Brut::CLI::Apps` |
| `deploy/Dockerfile` | Template `Dockerfile` used to create a `Dockerfile` for each process type | Heroku requires each process (web, worker, release, etc.) to have its own `Dockerfile` and own image |
| `deploy/heroku_config.rb` | Class that exports optional processes | By default, your app has a web and release process. `HerokuConfig` can export others, like Sidekiq |
| `deploy/docker-entrypoint` | The [`ENTRYPOINT`](https://docs.docker.com/reference/dockerfile/#entrypoint) for production Docker images, which is set up to use jemalloc | You can modify or remove this as needed |

How to deploy:

1. Get an auth token from Heroku, which you can do from inside the container, and save it to
   `bash_customizations.local`:

   ```
   your-computer> dx/exec bash
   devcontainer> heroku auth:login
   # You will need to copy/paste the URL to log in
   devcontainer> heroku authorizations:create -d "container pushes" --expires-in 31536000
   # Copy the token output by this command
   devcontainer> echo "HEROKU_API_KEY=«TOKEN YOU COPIED»" >> dx/bash_customizations.local
   ```
2. Exit the devcontainer and  stop `dx/start` (e.g. hit `Ctrl-C` wherever you ran it)
3. Rebuild and restart the devcontainer (this will set `HEROKU_API_KEY` for you)

   ```
   your-computer> dx/build
   your-computer> dx/start
   # In another terminal window
   your-computer> dx/exec bash
   devcontainer> echo $HEROKU_API_KEY
   # You should see the token
   ```

   Setting this environment variable avoids having to constantly re-authenticate to Heroku.

4. Create your app using the container stack:

   ```
   > heroku create --stack container -a «your heroku app name»
   ```
5. Ensure your app's source code is all checked in, there are no uncommitted or unadded files, and you have pushed to the `main` branch of your remote Git repository.
6. `bin/deploy`

   This will generate a `Dockerfile` for each process (by default, `Dockerfile.web` and `Dockerfile.release`), build images, push those images to Heroku, and ask Heroku to release them.

Debugging Tips:

* Keep in mind it's hard to make general deployment tools. You are expected to understand your deployment and be capable of deploying an arbitrary Rack app manually.  Brut's tooling automates what you need to do based on what you already need to know.
* `bin/deploy` runs the `deploy` subcommand, so `bin/deploy help deploy` can provide some options for debugging issues:

  ```
  devcontainer> bin/deploy help deploy
  Usage: bin/deploy [global options] deploy [command options] 

      Build images, push them to Heroku, and deploy them

      Manages a deploy process based on using Heroku's Container Registry. See

      https://devcenter.heroku.com/articles/container-registry-and-runtime

      for details. You are assumed to understand this.
      This command will make the process somewhat easier.

      This will use deploy/Dockerfile as a template to create
      one Dockerfile for each process you want to run in Heroku.
      deploy/heroku_config.rb is where the processes and their
      commands are configured.

      The release phase is included automatically, based on bin/release.

  GLOBAL OPTIONS

      -h, --help            Get help
          --log-level=LEVEL Set log level. Allowed values: debug,
                            info, warn, error, fatal. Default 'fatal'
          --verbose         Set log level to 'debug', which will produce
                            maximum output

  ENVIRONMENT VARIABLES

      BRUT_CLI_RAISE_ON_ERROR - if set, shows backtrace on errors
      LOG_LEVEL               - log level if --log-level or --verbose is omitted


  COMMAND OPTIONS

          --platform=PLATFORM  Override default platform. Can be any Docker
                               platform.
          --[no-]dry-run       Print the commands that would be run and
                               don't actually do anything. Implies --skip-checks
          --[no-]skip-checks   Skip checks for code having been
                               committed and pushed
          --[no-]deploy        After images are pushed, actually deploy them
          --[no-]push          After images are created, push them
                               to Heroku's registry. If false,
                               implies --no-deploy
  ```
* Try building images first: `bin/deploy deploy --no-push --skip-checks`
* It's possible to run the images locally.  If you are on Apple Silicon, you'll
  need to set --platform:

  * `bin/deploy deploy --no-push --skip-checks --platform linux/arm64`
  * Create `docker-compose.yml` for your image and any other services e.g. databases
  * Set required environment variables in `docker-compose.yml`
  * Start up Docker compose and poke around

  You'll need to have a better understanding of Docker to do this, however if you
  are deploying with Docker, this is an understanding you hopefully already have.

### Other Mechanisms for Deployment

As a Rack app, other deployments should be possible.  To make the app work, you'll need to make sure a few things are dealt with:

* `RACK_ENV` **must** be `"production"`
* `bin/build-assets` will build all assets by default.  This must either be done on production servers or done ahead of time and the results packaged with the app.
* `bin/build-assets` outputs files in `app/public` and `app/config`.  Those files are used at runtime.  Brut **will not** initiate the build of any assets.
* If you are going to build assets on production servers, you *must* included developer tooling. This means NodeJS, all modules in `package.json` and all RubyGems in `Gemfile`.

The `deploy/Dockerfile` created by `mkbrut --segment-heroku` is not very Heroku-specific and could serve as a reference.

## Testing

Testing deployments is a bit out of scope, but in general:

* A container-based deployment can theoretically be run on your computer as a test.
* Non-production, but production-like environments can be used to validate production configurations.
* You own the means of production…not Brut.

## Recommended Practices

* Avoid a lot of code that checks `Brut.container.project_env`.  Try to consolidate all prod/test/dev differences in environment variables.
* Have a way to get a shell into your production environment for debugging.
* Brut doesn't log much, but if you remove the `OTEL_*` environment variables, Brut will log OTel telemetry to the console, which may be useful. 
* Setting `OTEL_LOG_LEVEL=debug` is advised if the app isn't starting or you aren't seeing any telemetry or logging

## Technical Notes

> [!IMPORTANT]
> Technical Notes are for deeper understanding and debugging. While we will try to keep them up-to-date with changes to Brut's
> internals, the source code is always more correct.

_Last Updated July 3, 2025_

None at this time.
