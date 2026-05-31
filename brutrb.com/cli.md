# CLI and Tasks

Your app will likely need command-line or non-browser-based tasks.  Outside of standard needs like running a dev server or managing the database, you will have app-specific needs, like transforming data or performing one-time bulk operations.

In Brut, these are done as Ruby CLI apps, powered by the standard library's `OptionParser`.  There is
more ceremony required than making a simple Rake task, but the end result is a canonical CLI app and
not a strange task-like thing with weird invocation syntax.

## Overview

In Brut, a CLI has two pieces: a `bin/` file that you run, e.g. `bin/notifications`, and then one or
more classes in `app/src/cli/` that implement the CLI through a series of potentially nested commands.

### `bin` file

The bin file has a shebang, some requires and setup, then creates `Brut::CLI::Runner`, which takes
your class and runs it.

Here is an example:

```ruby {7,10}
#!/usr/bin/env ruby

require "fileutils"
require "brut"
APP_PATH = File.join(File.dirname($0),"..","app","src")
$: << APP_PATH
require "cli/notifications" # this requires app/src/cli/notifications.rb

runner = Brut::CLI::Runner.new(
  NotificationsCLI.new, # this is assumed to be defined in app/src/cli/notifications.rb
  stdout: $stdout,
  stderr: $stderr,
  stdin: $stdin,
  project_root: Pathname($0).dirname / ".."
)
exit runner.run!(ARGV,ENV)
```

The two higlighted lines are the only lines different amongst all your CLIs.

Your CLI **must** be invoked with `bundle exec`:

```
> bin/notifications
# => produces a massive stack trace
> bundle exec bin/notifications
# => works
```

### Implementation Classes

`app/src/cli` is the root for your CLI classes.  By convention, these end in `CLI`, but this is not
required.  The class you pass to `Brut::CLI::Runner` in your `bin/` file *must* extend
`Brut::CLI::Commands::BaseCommand`.  It should also override several key methods, including `run`,
which performs whatever logic your CLI needs to perform.

Here is a minimal oveview of how you would structure this class:

```ruby
class NotificationsCLI < Brut::CLI::Commands::BaseCommand

  def description = "Manages app notifications"

  def run
    # logic goes here
  end
end
```

#### Implementing Logic

Inside `run`, you can put whatever code you need to make your CLI work. Your CLI will need to be run in
one of three possible states:

1. Brut not configured nor bootstrapped
2. Brut configured, but not bootstrapped, e.g. you could access the database URL, but the connection to
   the database would not have been accessed and the database doesn't have to be up.
3. Brut fully bootstrapped.

Based on what you need, you will need to implement methods in your command.

| Configured? | Bootstrapped? | Code | Why |
| ---         | ---           | ---  | --- |
| No          | No            | Nothing Extra | Logic that runs outside of a `RACK_ENV` and doesn't require access to databases or other runtime data | 
| Yes         | No            | `def default_rack_env = "..."` | Logic that must access Brut configuration values and whose behavior depends on the `RACK_ENV` |
| Yes         | Yes           | `def default_rack_env = "..."` and `def bootstrap? = true` | Logic that will access external data stores like the database |

If your CLI is not going to access any of your business logic and isn't going to use
`Brut.container.XXX`, you don't need anything extra.  If you *do* access `Brut.container.XXX` you
*must* define an environment either on the command line or by default.  If you need to access business
logic, you will need Brut fully bootstrapped, so you must *also* defined `bootstrap?` to return true.

> [!NOTE]
> `default_rack_env`  and `bootstrap?` apply to each command separately. You cannot specify these
> concepts for your entire CLI.

::: code-group

```ruby [No Config/Bootstrapping]
class NotificationsCLI < Brut::CLI::Commands::BaseCommand

  def description = "Manages app notifications"

  def run
    # Brut.container.XXX will fail here
    # Any business logic will fail
  end
end
```

```ruby [Config Only]
class NotificationsCLI < Brut::CLI::Commands::BaseCommand

  def description = "Manages app notifications"
  def default_rack_env = "development"

  def run
    # Brut.container.XXX will work
    # Any business logic will fail
  end
end
```

```ruby [Fully Bootstrapped]
class NotificationsCLI < Brut::CLI::Commands::BaseCommand

  def description = "Manages app notifications"
  def default_rack_env = "development"
  def bootstrap? = true

  def run
    # Brut.container.XXX will work
    # Any business logic will work
  end
end
```
:::

#### Input/Output and Spawning Commands

All commands are created with a `Brut::CLI::ExecutionContext`, which provides access to standard
input, standard output, standard error, parsed options, the UNIX environment, and the ability to spawn
subprocesses.

The reason for this indirection is a) to automatically provide more useful behaviors like logging and
error handling, and b) to afford testing.

While you can access the `ExecutionContext` via `#execution_context`, there are several convienience
methods:

* `argv` -  Provides access to any unparsed arguments from the command line.
* `system!` - Invoke a subcomand that is assumed to succeed.
* `puts` - Output message to the standard output
* `debug(message)` - Log a debug message
* `info(message)` - Log in informational message
* `warn(message)` - Log a warning message
* `error(message)` - Log an error message
* `fatal(message)` - Log a fatal error message
* `stdin` - Access the standard input
* `options` - Access the parsed options as a `Brut::CLI::Options` (see below)
* `env` - Access the UNIX enviornment.

You are encourged to use these and not e.g. `ENV` or `$stdin`.

```ruby

# WRONG
def run
  admin = ENV["ADMIN_EMAIL"]
  $stdout.puts "Admin is #{admin}"
end

# CORRECT
def run
  admin = env["ADMIN_EMAIL"]
  puts "Admin is #{admin}"
end

# OK, BUT TOO VERBOSE
def run
  admin = @execution_context.env["ADMIN_EMAIL"]
  @execution_context.stdout.puts "Admin is #{admin}"
end
```

### Subcommands

Brut CLIs are designed to allow for subcommands, e.g. `git show` or `brut db`.  `brut` uses this
facility.

To declare subcommands, `commands` must return an array of instantiated
`Brut::CLI::Commands::BaseCommand` instances.  Practically speaking, any inner class of a command that
is a subclass of `Brut::CLI::Commands::BaseCommand` will be included if you don't override `commands`.

::: code-group

```ruby [Default Behavior]
class NotificationsCLI < Brut::CLI::Commands::BaseCommand

  def description = "Manages app notifications"

  # bin/notifications email
  class Email < Brut::CLI::Commands::BaseCommand
    # ...
  end

  # bin/notifications sms
  class Sms < Brut::CLI::Commands::BaseCommand
    # ...
  end
end
```

```ruby [Explicit Implementation] {15-18}
class NotificationsCLI < Brut::CLI::Commands::BaseCommand

  def description = "Manages app notifications"

  # bin/notifications email
  class Email < Brut::CLI::Commands::BaseCommand
    # ...
  end

  # bin/notifications sms
  class Sms < Brut::CLI::Commands::BaseCommand
    # ...
  end

  def commands = [
      Email.new,
      Sms.new
  ]
end
```

```ruby [Custom Behavior] {15-17}
class NotificationsCLI < Brut::CLI::Commands::BaseCommand

  def description = "Manages app notifications"

  # bin/notifications email
  class Email < Brut::CLI::Commands::BaseCommand
    # ...
  end

  # bin/notifications sms NOT SUPPORTED
  class Sms < Brut::CLI::Commands::BaseCommand
    # ...
  end

  def commands = [
      Email.new,
  ]
end
```
:::

In this way, the main command (`NotificationsCLI` in the running example) can serve as a namespace.
If invoked without a subcommand, Brut provides an error indicating a command is required. You *can*
override `run` to provide default behavior, including delegating to another command:

```ruby {5}
class NotificationsCLI < Brut::CLI::Commands::BaseCommand

  def description = "Manages app notifications"

  # Allows bin/notifications to be the same as bin/notifications email
  def run = delegate_to_command(Email.new)

  # bin/notifications email
  class Email < Brut::CLI::Commands::BaseCommand
    # ...
  end

  # bin/notifications sms
  class Sms < Brut::CLI::Commands::BaseCommand
    # ...
  end
end
```

### Command-line Flags and Options


Options are declared by overriding `opts` to return an array of arrays. Each element of the outer
array is the set of arguments to pass to `OptionParser.on` from the standard library.

```ruby
def opts = [
    [ "--verbose" ],
    [ "--debug", "Set DEBUG mode" ],
    [ "--env ENV", "-e", "Set Rack environment" ],
    [ "--count NUM", Integer, "How many times to run" ],
    # etc.
]
```

Brut CLIs accept a single set of options/flags.  This means that these invocations are equivalent:

```
> bundle exec bin/notifications --debug sms --dry-run
> bundle exec bin/notifications --debug --dry-run sms
> bundle exec bin/notifications sms --debug --dry-run
```

The options/flags that are accepted are the set of all options/flags declared by each namespace and
the command that was invoked.  Consider:

```ruby
class NotificationsCLI < Brut::CLI::Commands::BaseCommand

  def description = "Manages app notifications"

  def run = delegate_to_command(Email.new)
  def opts = [
    [ "--debug", "Show more debugging info" ],
  ]

  # bin/notifications email
  class Email < Brut::CLI::Commands::BaseCommand
    # ...
  end

  # bin/notifications sms
  class Sms < Brut::CLI::Commands::BaseCommand
    def opts = [
      [ "--[no-]dry-run", "If set, no files will be changed, no SMS sent" ],
    ]
    # ...
  end
end
```

Here, both `Email` and `Sms` accept `--debug`, but only `Sms` accepts `--dry-run` (or `--no-dry-run`).

To access the options, the private method `options` returns a `Brut::CLI::Options` instance.  This
provides a richer interface than a `Hash` (though you can treat it as a hash if you like).

Each option recognized can be accessed via a method with that options name, where dashes are replaced
with underscores.  In the example above, `options.debug` and `options.dry_run` would provide you the
values passed on the command line.  You can also add a `?` to get a boolean-coerced value, for example
`options.dry_run?`.

## Recommended Practices

If your CLI requires bootstrapping, it should defer to some other class in `app/src/back_end`.
Otherwise, including it in the CLI class should be fine, since it can be tested conventionally.


## Testing

Your CLI classes can be tested conventionally by instantiating them, however you should not call
`run`, but instead call `execute`, which accepts a `Brut::CLI::ExecutionContext`.  If your test
includes `cli_command: true` in its metadata, or includes `Brut::SpecSupport::CLICommandSupport`, the method `test_execution_context` should be used to create an `ExecutionContext`.

By default, it will set it up with reasonable values, but you can override them as you need to.
For example, you may want to pass a `StringIO` in for `stdout:` to examine the standard output.

Also of note, the `have_executed` matcher allows you to check what sub processes your command
executed.  The default `ExecutionContext` returned by `test_execution_context` will not run any
external commands and simply capture them. `have_executed` is a way you can check what it would
execute for real:

```ruby
RSpec.describe NotificationsCLI, cli_command: true do

  it "should run rsync" do
    execution_context = test_execution_context

    result = described_class.new.execute(execution_context)

    expect(execution_context).to have_executed([
      "rsync --archive --verbose \"/images/src/\" \"/images/root\"",
    ])
  end
end
```

## Technical Notes

> [!IMPORTANT]
> Technical Notes are for deeper understanding and debugging. While we will try to keep them up-to-date with changes to Brut's
> internals, the source code is always more correct.

_Last Updated May 31, 2026_

CLIs use the standard library's `OptionParser` internally, and much of the API mirrors that API.  

Bootstrapping can be more clearly understood by examining the `Bootstrap` class `brut new` generated in
your app.  Currently, the three stages work like so:

1. **Not configured, nor bootstrapped.** Brut and Bundler have not been required, none of your app's
   gems are available.  This stage is as if you are running a plain Ruby script.
2. **Configured, not bootstrapped.** Brut and Bundler have been required. Your gems are available. Your
   `App` has been required and your app's source code can be accessed. Nothing is set up beyond
   configuration values being available.  External data stores have not been connected-to. The
   underlying Sinatra app is not be created nor configured. Routes aren't available.  Any attempt to
   use business logic will probably fail.

   This mode is useful if you need access to configuration values to perform tasks that must work
   without external services. For example `brut db create` requires configuration but not
   bootstrapping, since it is going to create the database.
3. **Configured, bootstrapped.** Everything is set up, databases have been connected-to, etc.  While
   your app isn't running to receive HTTP requests, it's almost identical to that situation. You want
   to be in this state if your CLI is going to invoke business logic.  This is the equivalent of a
   Rails rake task depending on `:environment`.
