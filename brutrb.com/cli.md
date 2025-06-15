# CLI and Tasks

Your app will likely need command-line or non-browser-based tasks.  Outside of standard needs like running a dev server or managing the database, you will have app-specific needs, like transforming data or performing one-time bulk operations.

In Brut, these are done as Ruby CLI apps, powered by the standard library's `OptionParser`.

## Overview

The various commands installed with your Brut app in `bin/` are powered by Brut's CLI support. You can use this support to create your own tasks.

The main feature this provides is a consistent startup of your app's internals and configuration. This startup is almost exactly the same as the web app, so you can safely rely on connections to the database, the ability to queue jobs, or the behavior of your business logic. There's just no web server and no front-end.

### Brut CLI User Interface

All Brut CLI apps produce a user interface that should be familiar if you've used CLI apps that support subcommands, like `git`:

```
> git status
> git checkout
> git commit
```

Each Brut CLI invocation has six parts:

* The executable, e.g. `bin/db`
* *Global Options* which are strings that start witih one or two
dashes and control the behavior of the entire app, e.g. `--log-level=debug` These are optional and there can be any number of them.
* The subcommand, which is a single string indicating what actual
function to perform, e.g. `rebuild` in `bin/db rebuild`
* *Command Options* which are just like global options, but they
come *after* the command and apply only to that command
* Arguments, which are any strings left over after the *command
options* are parsed.

All of this is powered by Ruby's `OptionParser`, which results in a canonical, UNIX-like UI.

```
> bin/my_cli --global-option list --command-option arg1 arg2
  \----+---/ \-------+-----/ \-+/ \--------+-----/ \---+---/
       |             |         |           |           |
   Executable        |         |           |           |
                     |         |           |           |
                Command        |           |           |
                   Options     |                       |
                               |           |           |
                             Subcommand    |           |
                                           |           |
                                      Command          |
                                        Options        |
                                                       |
                                                       |
                                                    Arguments
        
```

Brut CLI apps all respond to `-h` and `--help` to view the list of subcommands, global options, and any environment variables that affect the behavior.

```
> bin/db -h 
bin/db [global options] commands [command options] [args]

   Manage your database in development, test, and production

GLOBAL OPTIONS

    -h, --help                       Get help
        --log-level=LEVEL            Set log level. Allowed values: debug, info, warn, error, fatal. Default 'fatal'
        --verbose                    Set log level to 'debug', which will produce maximum output

ENVIRONMENT VARIABLES

    BRUT_CLI_RAISE_ON_ERROR - if set, shows backtrace on errors
    LOG_LEVEL               - log level if --log-level or --verbose is omitted


COMMANDS

    help          - Get help on a command
    create        - Create the database if it does not exist
    drop          - Drop the database if it exists
    migrate       - Apply any outstanding migrations to the database
    new_migration - Create a new migration file
    rebuild       - Drop, re-create, and run migrations, effecitvely rebuilding the entire database
    seed          - Load seed data into the database
    status        - Check the status of the database and migrations
```

Brut CLI apps also support the subcommand `help` which will show help on a given subcommand, including the command options and arguments.

```
>  bin/db help rebuild
Usage: bin/db [global options] rebuild [command options] 

    Drop, re-create, and run migrations, effecitvely rebuilding the entire database

GLOBAL OPTIONS

    -h, --help                       Get help
        --log-level=LEVEL            Set log level. Allowed values: debug, info, warn, error, fatal. Default 'fatal'
        --verbose                    Set log level to 'debug', which will produce maximum output

ENVIRONMENT VARIABLES

    BRUT_CLI_RAISE_ON_ERROR - if set, shows backtrace on errors
    LOG_LEVEL               - log level if --log-level or --verbose is omitted
    RACK_ENV                - default project environment when --env is omitted


COMMAND OPTIONS

        --env=ENVIRONMENT            Project environment (default 'development')
```

All of this means that the bulk of CLI-specific code you will write is specifying these options and documentation, then deferring to your business logic.

### Basic CLI

Every CLI app is a class that extends `Brut::CLI::App`. This class should contain one inner class for each subcommand. Those classes should extend `Brut::CLI::App`.

Inside your `Brut::CLI::App` class, you can call a few class methods to declare aspects of the UI. In particular, `opts` returns the `OptionParser` in play that you can use to declare global options.  Unlike `OptionParser`'s `on` method, Brut's does not require providing a block. Brut will store the runtime options in a hash (see below).

```ruby
class MyAppCLI < Brut::CLI::App
  description "My awesome command line app"

  opts.on("--dry-run", "Only show what would happen; don't change anything")
  opts.on("--status STATUS", "Set the status you'd like to see")
end
```

This code means your app's global options are `--dry-run`, which will not accept an argument, and `--status` which *must* be given an argument.  The arguments to `on` are the same as those for Ruby's `OptionParser`.

Declaring subcommands provides a similar API.  Let's say our app has a "status" subcommand, and a "run" subcommand.

```ruby
class MyAppCLI < Brut::CLI::App
  description "My awesome command line app"

  opts.on("--dry-run", "Only show what would happen; don't change anything")
  opts.on("--status STATUS", "Set the status you'd like to see")

  class Status < Brut::CLI::Command
    description "Show the status"
    args "files to get the status of"
    opts.on("-l", "--long", "Show long-format")
  end

  class Run < Brut::CLI::Command
    description "Run any outstanding tasks"
    opts.on("--exit-status STATUS", "Exit status on success")
  end
end
```

This enables commands like `bin/my_app status -l foo.txt bar.rb` or `bin/my_app status --exit-status=3`.

The names are derived from the class name. You can override them by using `command_name` inside a command class.

```ruby {2}
class Run < Brut::CLI::Command
  command_name "exec"
  
  # ...
end
```

The only thing left is to specify what happens for each subcommand. To do that, implement `execute`.

```ruby {6-8,15-17}
class Status < Brut::CLI::Command
  description "Show the status"
  args "files to get the status of"
  opts.on("-l", "--long", "Show long-format")

  def execute
    # ...
  end
end

class Run < Brut::CLI::Command
  description "Run any outstanding tasks"
  opts.on("--exit-status STATUS", "Exit status on success")

  def execute
    # ...
  end
end
```

### Implementing `execute`

Once `execute` is called, your app's internals will have been setup and bootstrapped. That means all you data models can access the database, and any other setup will have ocurred. Generally, `execute` can then have whatever code makes sense.

That said, `execute` has access to a few values to understand the command line invocation and to support testing.

* `#options` - the command options passed on the command line, as
a `Brut::CLI::Options`
* `#global_options` - the global options passed on the command line, as a `Brut::CLI::Options`
* `#args` - the args passed on the command line, as an array of
strings
* `#out` - an IO you should use to print messages to the standard out.
* `#err` - on IO you should use to print messages to the standard error.
* `#system!` - the method you should use to spawn child processes.
This is preferable to `Kernel.system` because the command executed will be logged, and your app will raise if the command fails.  This makes it more straightfoward to safely script other command line invocations.

### Advanced Options

The API documentation will show you other options for creating your CLI UI, but there are a few aspects to highlight.

* Calling `configure_only!` in your app, will run your app's
subcommands without starting up Brut. This is generally not needed, but can be useful if you want to do basic scripting without worrying about connecting to the database.
* `default_command` can be used to specify the command to run if
none is given.  `bin/test` uses this to run `bin/test run`.
* `requires_project_env` can be used at the app or command level
to indicate that `--env` is accepted on the command line to set the project environment for the code to run in. Omitting this means that the actual project env used when the app runs is undefined.
* Use `env_var` to document environment variables your app will
use that affect its behavior.

### The file in `bin`

Currently, Brut doesn't provide a way to create this file, but it's relatively straightforward.  It's almost entirely boilerplate except for your class:

```ruby {14}
#!/usr/bin/env ruby

require "bundler"
Bundler.require
require "pathname"

require "brut/cli"

APP_PATH = File.join(File.dirname($0),"..","app","src")
$: << APP_PATH
require "cli/my_app"

exit Brut::CLI.app(
  MyAppCLI,
  project_root: Pathname($0).dirname / ".."
)
```

## Testing

Depending on how your CLI is impelmented, testing it may not be that beneficial.  If `execute` simply defers to your back-end, your tests of that back-end will generally suffice.

That said, your command classes are normal Ruby classes, so you can test them in a conventional way.

The initalizer of each command class looks like so:

```ruby
def initialize(
  command_options:,
  global_options:,
  args:,
  out:,
  err:,
  executor:
)
```

`command_options` and `global_options` accept a `Brut::CLI::Options`, which can be created with a Hash to represent the parsed command line options.

`args` is a list of Strings.  `out` and `err` are IOs, so you can use the standard library's `StringIO` to both capture the output and supress it from your test's standard output/error.

`executor` is a `Brut::CLI::Executor`, which is a wrapper around the standard library's `Open3`.  You can mock this to set expectations on what child processes are launched and how they behave.

## Recommended Practices

`execute` should defer to classes in your back-end, ideally a single method of a single class.  Excessive logic or UI in your CLI will be hard to test and maintain.


## Technical Notes

> [!IMPORTANT]
> Technical Notes are for deeper understanding and debugging. While we will try to keep them up-to-date with changes to Brut's
> internals, the source code is always more correct.

_Last Updated May 9, 2025_
