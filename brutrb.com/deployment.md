# Deployment

Brut apps are Rack apps, so they can be deployed in conventional
ways.

## Overview

There are just too many ways to deploy.  Brut attempts to address this by adhering to [12-factor principles](https://12factor.net).  You can get your app to production and run `bin/run` and it should work.

That said, Brut currently provides explicit support for two methods of deployment: Heroku (using containers) and a generalized Docker Image mechanism.

### General Design of Deployment

Brut attempts to consolidate all production deployment configuration in `deploy/deploy_config.rb`,
     which is expected to define the class `AppDeployConfig`, which is expected to extend `Brut::CLI::Apps::Deploy::DeployConfig`.  Brut will create an instance of this class and use it to understand production aspects of your deployment.  No YAML.

At its most basic, in production you will need to know what long-running processes to run. By default, you'd run a web process, but you may also run Sidekiq or other services that need access to your app's source code.

The most full-featured method currently supported is Heroku, using containers.


### Heroku Container-based Deployment

When creating your Brut app with `brut new`, the Heroku segment can be used to create files for a [Heroku container-based deployment](https://devcenter.heroku.com/articles/container-registry-and-runtime).

If you already created your app, you can add this segement via:

```bash
brut new segment heroku
```

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
6. `brut deploy heroku`

   This will generate a `Dockerfile` for each process (by default, `Dockerfile.web` and `Dockerfile.release`), build images, push those images to Heroku, and ask Heroku to release them.

Debugging Tips:

* Keep in mind it's hard to make general deployment tools. You are expected to understand your deployment and be capable of deploying an arbitrary Rack app manually.  Brut's tooling automates what you need to do based on what you already need to know.
* Try building images first: `brut deploy heroku --build-only`
* It's possible to run the images locally, but you will ned to run Postgres at the very least.

### General Docker Image Deployment

When creating your Brut app with `brut new`, the DockerDeploy segment can be used to create files for a [Heroku container-based deployment](https://devcenter.heroku.com/articles/container-registry-and-runtime).

If you already created your app, you can add this segement via:

```bash
brut new segment docker-deploy
```

This segment provides a more generic method of deployment using Docker images and Docker registries. Under this method, you author a `Dockerfile` which is then used to build an image whose name is based on your app's org and id (as defined in your subclass of `Brut::Framework::App`), as well as the current SHA-1 of your git repo.  This image is then pushed to a
registry of your choice.  After that push, you are on your own to pull it down somewhere.

```bash
brut deploy docker
```

You can do `brut deploy docker --no-push` to build only.

If you aren't using DockerHub, you can set your registry in `deploy/deploy_config.rb`:

```ruby
class AppDeployConfig < Brut::CLI::Apps::Deploy::DeployConfig
  def registry_hostname = "ghcr.io"
end
```

#### Management of a `docker-compose.yml`

If you want to use Docker Compose in production, Brut can assist with managing the `docker-compose.yml`
file.

```bash
brut deploy docker_compose generate
```

This will create a `deploy/docker-compose.yml` if one is not there.  It will have default settings that
have worked for me, but you should review this file and make sure it's correct.

If the file **is** there, Brut will make it consistent with your `deploy/deploy_config.rb` file:

* Any service in `docker-compose.yml` that is not part of your config is removed
* Any service *not* in `docker-compose.yml` will be added
* Services in both `docker-compose.yml` and your config will be updated in `docker-compose.yml` as
follows:
  - `command:` will be set to the command in your config
  - `image:` will be set to `REGISTRY/ORG/APP_ID:${DOCKER_IMAGE_TAG}`, where `REGISTRY` is the value
  from your deploy config and `ORG` and `APP_ID` are from your `App` class.  Your production
  environment is expected to set `DOCKER_IMAGE_TAG` in the UNIX environment.  This is because Brut's
  `brut deploy docker` implementation does not use `latest`, since `latest` in Docker-land is
  absolutely cursed.

Instead of changing the file, you can check its consistency first:

```bash
brut deploy docker_compose check
```

This will output differences between what `generate` would do and what exists.

> [!NOTE]
> Brut assumes your `deploy/docker-compose.yml` is to be checked in, so if you use
> `brut deploy docker_compose generate` to update it, you must commit and push
> that change to use `brut deploy docker`.

### Other Mechanisms for Deployment

As a Rack app, other deployments should be possible.  To make the app work, you'll need to make sure a few things are dealt with:

* `RACK_ENV` **must** be `"production"`
* `brut build-assets` will build all assets by default.  This must either be done on production servers or done ahead of time and the results packaged with the app.
* `brut build-assets` outputs files in `app/public` and `app/config`.  Those files are used at runtime.  Brut **will not** initiate the build of any assets.
* If you are going to build assets on production servers, you *must* included developer tooling. This means NodeJS, all modules in `package.json` and all RubyGems in `Gemfile`.

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
