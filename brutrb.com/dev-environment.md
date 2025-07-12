# Dev Environment

Brut provides sophisticated tooling to manage your dev environment

## Overview

A development environments or *dev environment* is made up of two parts:

* *Foundational Core* - the operating system and tools needed to run the app and *its* tools. This
includes language runtimes, system libraries (like ImageMagick), and system tools like web browsers.
* *Workspace* - the tools and code bundled with the app that you use day-to-day to work on the app itself.
This would include scripts to run the app in development, run tests, perform scaffolding, or manage the
database.

On many teams, the Foundational Core is different per developer, since some run Linux, some run MacOs.
Some might use mise to manage their version of Ruby while others use rbenv.  Some will set up Postgres via
homebrew, while others might use Popstgres.app.

Brut takes a different approach.  Everyone shares the same Foundational Core, and this is defined by a
`Dockerfile`, a `docker-compose.yml` file, and some lightweight Bash scripts.

This means that everyone uses the same version of everything, and they are all managed the same way.

Brut also provides sophisticated tooling for the Workspace.  Like Rails, Brut provides a command-line
based flow that can be scripted into any editor.  Unlike Rails, Brut's Workspace is comprised of separate
command-line apps and not Rake tasks.

### Conceptual Overview

Your dev environment consists of a Docker container that has languages, an operating system, and other
system components installed in it.  It will have access to the files on your computer so that it can run
your app. The app will be exposed so that a browser on your computer can access it.  Postgres will be run
as a separate Docker container available to the dev Docker container.

Your editor and version control system run on your computer.

![Diagram showing the parts of the dev environment. The foundational core is also
labeled "Docker containers" and it contains three boxes labeled "Container".  One
box contains ValKey, another contains Postrgres. The third box contains "Your Brut
App", "NodeJS", "Ruby", and part of "Source Code". The "Source Code" also also
partially inside a box containing the foundational core labeled "Your Computer".
This box contains "Browser" and "source code editor".](/images/DevEnvironment.png)  

### Foundational Core Command Line Apps

These are the commands you will use to manage the *foundational core*, which is the Docker containers and
their contents.

A few brief terminology notes if you aren't familiar with Docker:

* A Docker *container* is akin to a virtual machine. On Linux this isn't strictly true, but conceptually, you can think of this like a virtual computer.
* A Docker *image* is what you use to start a container.  This is akin to a disk image you might use to
create a new computer or virtual machine.
* A Dockerfile (often named `Dockerfile`) is a set of instructions to create an image.

A few verbs to provide additional help:

* One *builds* a Docker image from a Dockerfile.
* One *starts* a Docker container from an image.
* One *stops* a Docker container when it's no longer needed.


| App        | Purpose                                                                |
|------------|------------------------------------------------------------------------|
| `dx/build` | Builds a Docker *image* from a `Dockerfile.dx`                         |
| `dx/start` | Starts all Docker containers, including those for databases and caches |
| `dx/stop`  | Stops all Docker containers                                            |
| `dx/exec`  | Execute a command inside a running Docker container                    |

The workflow for the foundational core is shown in this diagram.

![Foundational Core Workflow](/images/dev-env-protocol.png)

In words:

1. You build the images based on the latest instructions via `dx/build`.
2. You start up the environment with `dx/start`.
3. You then use `dx/exec` to execute commands from the Workspace (see below).
4. When you are done working for the day, `dx/stop` shuts everything down.

### Workspace Command Line Apps

The workspace is where you'll run your day-to-day commands, such as running tests, starting the dev
server, managing the database schema, etc.

Several of the commands accept or require subcommands.  Each CLI app responds to `--help` and will show
you full documentation about what the command and subcommands do.

| App             | Subcommand            | Descriptions                                                                              |
|-----------------|-----------------------|-------------------------------------------------------------------------------------------|
| <code style="white-space: nowrap">bin/ci</code>        | None                  | Runs all tests and security checks                                                        |
| <code style="white-space: nowrap">bin/console</code>   | None                  | Starts up a local IRB session with your app loaded                                        |
| <code style="white-space: nowrap">bin/db</code>        |                       | Tools for managing the database                                                           |           |
|                 | `create`              | Create the database if it does not exist                                                  |
|                 | `drop`                | Drop the database if it exists                                                            |
|                 | `migrate`             | Apply any outstanding migrations to the database                                          |
|                 | `new_migration`       | Create a new migration file                                                               |
|                 | `rebuild`             | Drop, re-create, and run migrations, effectively rebuilding the entire database           |
|                 | `seed`                | Load seed data into the database                                                          |
|                 | `status`              | Check the status of the database and migrations                                           |
| <code style="white-space: nowrap">bin/dbconsole</code> | None                  | Starts up a `psql` session to your database                                               |
| <code style="white-space: nowrap">bin/dev</code>       | None                  | Starts the app in dev mode, rebuilding assets and reload as needed                        |
| <code style="white-space: nowrap">bin/setup</code>     | None                  | Install and setup all third party libraries and other configuration needed to use the app |
| <code style="white-space: nowrap">bin/scaffold</code>  |                       | Generate Brut classes or files like database migrations or page classes                   |
|                 | `action`              | Create a handler for an action                                                            |
|                 | `component`           | Create a new component and associated test                                                |
|                 | `custom_element_test` | Create a test for a custom element in your app                                            |
|                 | `form`                | Create a form and handler                                                                 |
|                 | `page`                | Create a new page and associated test                                                     |
|                 | `db_model`            | Create one or more database models, specs, and factories, plus a migration to create the tables for those models |
|                 | `test`                | Create the shell of a unit test based on an existing source file                          |
|                 | `test:e2e`            | Create the shell of an end-to-end test                                                    |
| <code style="white-space: nowrap">bin/test</code>      |                       | Run tests |
|                 | `audit`               | Audits all of the app's classes to see if test files exist                                |
|                 | `e2e`                 | Run e2e tests                                                                             |
|                 | `js`                  | Run JavaScript unit tests                                                                 |
|                 | `run`                 | Run non-e2e tests (default)                                                               |


The workflow for your Workspace is shown in this diagram

![Workspace Workflow](/images/workspace-protocol.png)

In words:

1. You'll run `bin/setup` to get everything set up for working.
2. You'll start your dev server with `bin/dev`.
3. You'll write code, using tools like `bin/db` and `bin/scaffold` to assist.
4. Using `bin/test`, you can test any code you've written a test for.
5. When you are at a stopping point, use `bin/ci` to test the entire app.

### Extending and Enhancing

TBD

## Testing

There aren't tests for this code, because you are using all day every day.  Brut's test suite will ensure
that the versions of these command line apps provided when you set up your app are working.

## Recommended Practices

While you are free to set up mise or rbenv or whatever to run all this on your computer, this way of
working is currently not supported nor encouraged.  For now, Brut will focus on the Docker-based approach.

The primary reason is that it's a tightly controlled environment that is almost
entirely scriptable, but does not require devs to abandon their preferred editor.
Environment manager-based approaches tend to be more fussy and require documentation
to ensure they are set up.

Keep in mind a few things when adding your own automation:

* The *Foundational Core* is bootstrapped in a degenerate environment without reliable tools beyond Bash.
This is why it's almost entirely written in Bash, since it's available everywhere and relatively stable.
* The *Workspace* **can and should** rely on the languages and third party modules that are part of your
app. The only exception is `bin/setup`, since it installs third party modules.  As such, it should work entirely based on Ruby and its standard library.

## Technical Notes

> [!IMPORTANT]
> Technical Notes are for deeper understanding and debugging. While we will try to keep them up-to-date with changes to Brut's
> internals, the source code is always more correct.

_Last Updated June 12, 2025_

Everything in `bin/` is intended to be a short shim that calls into classes managed either by Brut or by
your app. For example, here is `bin/db`:

```ruby
#!/usr/bin/env ruby

require "bundler"
Bundler.require
require "pathname"
require "brut/cli/apps/db"

exit Brut::CLI.app(
       Brut::CLI::Apps::DB,
       project_root: Pathname($0).dirname / ".."
     )
```

These files have some duplication, but should be relatively stable.

This means that Brut-provided CLIs *will*  be updated when you update Brut.  Compare this to the files in
`dx/` which are entire Bash scripts that will not be updated when Brut is updated.
