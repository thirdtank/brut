# Getting Started

Brut is developed alongside a separate gem called `mkbrut`, which allows you to
create a new Brut app. It will set up you dev environment as well.

## Get `mkbrut`

If you have a Ruby 3.4 (or later) environment set up on your computer, you can use 
RubyGems:

```
gem install mkbrut
```

If not, we recommend you use a pre-built Docker image:

```
docker pull XXXX
```

## Init Your App

A Brut app just needs a name, which will be used to derive a few more useful values.
For now:

```
mkbrut my-new-app
```

This will create your new app, along with some demo routes, components, handlers, and tests. If this is your first time using Brut, we recommend you examine these demo components.  However, if you just want to skip all that:

```
mkbrut --no-demo my-new-app
```

## Start Your Dev Environment

Brut includes a dev environment based on Docker.  It uses Docker compose to run a
Docker container where your app will run, a Docker container for Postgres, and a
Docker container for local observability via OpenTelemetry.

1. [Install Docker](https://docs.docker.com/get-started/get-docker/)
2. Build the image used to create you app's container:

   ```
   > dx/build
   ```
3. Start up all the containers:

   ```
   > dx/start
   ```
4. Install gems and modules for your app. In another terminal:

   ```
   > dx/exec bin/setup
   ```

   OR:

   ```
   > dx/exec bash
   inside-container> bin/setup
   ```

Now, you're ready to go

## Run the App

```
> dx/exec bin/dev
```

OR

```
> dx/exec bash
> bin/dev
```

You can now visit your app at `localhost:6502`

## Run the Tests

Even without the demo, there are a few components set up, and there are some tests:

```
> dx/exec bin/ci
```

OR

```
> dx/exec bash
> bin/ci
```

## Now Build The Rest of Your App 🦉

You can [follow the tutorial](/tutorial), check out the [conceptual overview](/overview), or dive straight into the API docs.  You might also want to check out the docs for [LSP Support](/lsp).

