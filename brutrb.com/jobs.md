# Background Jobs

Brut ships without any background job system, however it should work with any system you'd like to use.  Brut
can install/configure Sidekiq for you, however you are expected to understand Sidekiq in order to use it.

## Setting up Sidekiq

Brut's code-generation system used for installing capabilities are called *segments*, and Brut provides a
Sidekiq segment you can use to get an initial working setup of Sidekiq in your Brut app.

### Adding the Segment

1. Ensure your project files are all committed. This is so you can easily see (and, if needed, undo) the
   changes `mkbrut` will make.
2. Use `mkbrut` to add the segment:

   ```
   docker run \
          --pull always \
          -v "$PWD":"$PWD" \
          -w "$PWD" \
          -u $(id -u):$(id -g) \
          -it \
          thirdtank/mkbrut \
          mkbrut add-segment -r /path/to/your/project sidekiq
   ```
3. This will modify and create various files in your project. Check them out if you like:

   ```
   > git status
   ```
4. Exit your dev environment (i.e. hit `Ctrl-C` wherever you ran `dx/start`).
5. Rebuild and restart your dev environment. This may take a moment, since Valkey will be downloaded.

   ```
   your-computer> dx/build
   your-computer> dx/start
   ```
6. In another Terminal, connect to your dev container and run `bin/setup`

   ```
   your-computer> dx/exec bash
   devcontainer> bin/setup
   ```
7. The segment provides an integration test that will use the actual Sidekiq server and client, running
   against the actual Valkey database that was installed:

   ```
   devcontainer> bin/test e2e specs/integration/sidekiq_works.spec.rb
   ```

If this test passes, you are ready to go.

### Using Sidekiq in Brut

Jobs live in `app/src/back_end/jobs`, however this is just a convention and is not enforced - you can place a
job anywhere that Zeitwerk will find the class.  Brut also provides basic configuration and a base job.

| File | Purpose|
|------|--------|
| `app/config/sidekiq.yml` | Standard configuration for Sidekiq |
| `app/src/back-end/jobs/app_job.r` | Base class for your jobs that includes `Sidekiq::Job` |
| `app/src/back-end/segments/sidekiq_segment.rb` | Initial client and server configuration for Sidekiq (that you can't do with `sidekiq.yml`. This sets up basic observability for your jobs |

### Accessing the Web UI

The Sidekiq segment mounts the Sidekiq Web UI to your app inside `config.ru`:

```ruby
# ...
map "/sidekiq" do
  use Rack::Auth::Basic, "Sidekiq" do |username, password|
    [username, password] == [ENV.fetch("SIDEKIQ_BASIC_AUTH_USER"), ENV.fetch("SIDEKIQ_BASIC_AUTH_PASSWORD")]
  end
  run Sidekiq::Web.new
end
# ...
```

Values for `SIDEKIQ_BASIC_AUTH_USER` and `SIDEKIQ_BASIC_AUTH_PASSWORD` for dev and test are placed into
`.env.development` and `.env.test`, respectively. You must provide these values for production, based on
however you are managing environment variables.

Once you start the app, navigat to `http://localhost:6502/sidekiq` and enter the username/password from
`.env.development`. You should see the web UI.

### Deploying with The Heroku Segment

If you have set up [Heroku Container-based Deployment](/deployment.md#heroku-container-based-deployment), you
may need to modify `deploy/heroku_config.rb`.  The Sidekiq segement should have edited this, however if you
installed the Heroku segment after setting up Sidekiq, you'll need to add to the file:

```ruby [2-6]
class HerokuConfig
  def self.additional_images
    {
      "sidekiq" => {
        cmd: "bin/run-sidekiq",
      }
    }
  end
end
```

## Setting Up Other Job Systems

To use another job system, you'll likely want to start with `app/src/app.rb`.  You can place all your
initialize code in `#boot!` to get things working, then factor it out from there.  `App`, the class in that
file, is a normal class, so you can extract your setup to other normal classes and bring them in as you would
in any other Ruby app.

Just note that `App`'s `initialize` method should avoid making network connections, so while you are safe to
create objects and configuration here, do not connect to databases or anything like that.  You *can* do that
inside `boot!`.
