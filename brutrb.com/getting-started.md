# Getting Started

Brut is developed alongside a separate gem called `mkbrut`, which allows you to
create a new Brut app. It will set up your dev environment as well.

## Get `mkbrut`

The simplest way to use `mkbrut` is to use an existing [Docker image](https://hub.docker.com/repository/docker/thirdtank/mkbrut/general).  You don't have to install or configure Ruby:

```
docker run \
       -v "$PWD":"$PWD" \
       -w "$PWD" \
       -it \
       thirdtank/mkbrut \
       mkbrut my-new-app
```

If you already have Ruby 3.4 installed, you can install `mkbrut` directly:

```
> gem install mkbrut
> mkbrut my-new-app
```

## Init Your App

A Brut app just needs a name, which will be used to derive a few more useful values.
For now:

::: code-group

``` [Docker-based]
docker run \
       -v "$PWD":"$PWD" \
       -w "$PWD" \
       -it \
       thirdtank/mkbrut \
       mkbrut my-new-app
```

``` [RubyGems-based]
mkbrut my-new-app
```

:::

This will create your new app, along with some demo routes, components, handlers, and tests. If this is your first time using Brut, we recommend you examine these demo components.

To create your app without the demo components:

::: code-group

``` [Docker-based]
docker run \
       -v "$PWD":"$PWD" \
       -w "$PWD" \
       -it \
       thirdtank/mkbrut \
       mkbrut my-new-app --no-demo
```

``` [RubyGems-based]
mkbrut my-new-app --no-demo
```

:::

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
4. Now, install your aps gems and set it all up:

   ```
   > dx/exec bin/setup
   ```

Now, you're ready to go.  See [Dev Environemnt](/dev-environment) for details on how
this all works.

> [!NOTE]
> Instead of running `dx/exec` in front of your commands, you
> can instead do `dx/exec bash` to "log in" to the running container.
> You'll have a normal prompt and can issue commands directly from there.

## Run the App

```
dx/exec bin/dev
```

You can now visit your app at `localhost:6502`

You can make changes and see them when you reload.  Open up `app/src/front_end/pages/home_page.rb` *in your editor running on your computer* and change the `h1` to look like so:

```ruby {6}
class HomePage < AppPage
  def page_template
    div(class: "flex flex-column items-center justify-center h-80vh") do
      img(src: "/static/images/icon.png", class: "h-50")
      h1(class: "ff-sans ma-0 lh-title f-5") do
        "Welcome to My New App!"
      end

      # ...
```

When you reload your browser, you'll see your change

## Run the Tests

There are a few tests you can run, as well as some checks that you aren't using
RubyGems with security vulnerabilities.  Run it all now with `bin/ci`:

```
dx/exec bin/ci
```

## Now Build The Rest of Your App 🦉

You can [follow the tutorial](/tutorial), check out the [conceptual overview](/overview), or dive straight into the [API docs](/api/index.html).  You might also want to check out the docs for [LSP Support](/lsp).

