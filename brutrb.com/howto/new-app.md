# HOWTO: Make a new Brut App

This will take you through how to make a new Brut app and make sure everything
is working.

## Initial the App with `brut new`

Brut includes a Docker-based dev environment, and doesn't require Ruby to be
installed to create a new app.

Use this following `docker run` command, wherever you want to create your new
app, which is called 'dei' in this example:

```
docker run \
       --pull always \
       -v "$PWD":"$PWD" \
       -w "$PWD" \
       -u $(id -u):$(id -g) \
       -it \
       thirdtank/brut \
       brut new dei --no-demo --no-interactive
```

If you `ls dei`, you should see directories and files for a new Brut app.
Next, you want to set up the dev environment.

### Creating an App with Sidekiq

If you know you will need Sidekiq, use this command instead of the one above:

```bash {9}
docker run \
       --pull always \
       -v "$PWD":"$PWD" \
       -w "$PWD" \
       -u $(id -u):$(id -g) \
       -it \
       thirdtank/brut \
       brut new dei --no-demo --no-interactive \
                    --segments sidekiq
```

This will ensure that Sidekiq is included and properly configured.  The
remaining steps below will include checks that Sidekiq is working.

### If you Plan to Deploy to Heroku

If you know you will deploy to Heroku, Brut supports container-based
deployment, so instead of the command above, run this:

```bash {9}
docker run \
       --pull always \
       -v "$PWD":"$PWD" \
       -w "$PWD" \
       -u $(id -u):$(id -g) \
       -it \
       thirdtank/brut \
       brut new dei --no-demo --no-interactive \
                    --segments heroku
```

Heroku deployment won't be tested until you actually deploy.

### If You Know You'll Need Heroku *and* Sidekiq

`--segments` takes more than one argument, so you can include both Heroku and
Sidekiq like so:

```bash {9}
docker run \
       --pull always \
       -v "$PWD":"$PWD" \
       -w "$PWD" \
       -u $(id -u):$(id -g) \
       -it \
       thirdtank/brut \
       brut new dei --no-demo --no-interactive \
                    --segments heroku,sidekiq
```

## Setting up the Dev Environment

Brut's dev environment is Docker-based, meaning all work is done in a
container.  That container will map your Brut app's source on your computer to
the same path in the container. You'll edit files locally using whatever editor
you want, and run commands inside the Docker container to build, run, and test
your app.

First, build the Docker image using `dx/build` (this assumes your app is named "dei"):

```
cd dei
dx/build
```

Next, you'll start it all up with `dx/start`:


```
dx/start
```

This is a wrapper around `docker compose up`, so `dx/start` will say running.
It's also running Postgres and otel-desktop-viewer (which you can use to
examine local OTel statistics).

You'll need to switch to another terminal to issue further commands.

In another terminal, you can execute commands inside the container by using
`dx/exec`.  We'll do that now to install and setup the app's gems, Node
modules, and databases.

```
dx/exec bin/setup
```

You can run `bin/setup` any time to reset or update your app's dependencies. It
will reset your database and apply all migrations.

## Verifying that the App is Working

`bin/setup` succeeding is a good sign things are working, but you'll want to
run tests and start the app as a final check.

First, run all checks with `bin/ci`

```
bin/ci
```

This will run unit tests, JS tests, and End-to-end tests. It will also check
that you don't have any gems containing known security vulnerabilities.

That should succeed - `brut new` created just enough tests to check this.

Now, run the app itself with `bin/dev`

```
bin/dev
```

This will output a URL where your app is running.  By default, this would be
`http://localhost:6502`.  Go there now. You should see a welcome screen.

You are encouraged to check all this into your version control system before
you start making changes.

## Learn More

* [`brut` cli reference](/brut-cli#new)
* [Tutorial](/tutorials/01-intro#the-blog-we-ll-build)

