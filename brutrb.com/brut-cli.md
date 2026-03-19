# `brut`

Brut CLI - interact with Brut and your app


## USAGE

    brut [options] command


## OPTIONS

* `--env=ENVIRONMENT` - Project environment, e.g. test, development, production. Default depends on the command
* `--log-level=LOG_LEVEL` - Log level, which should be debug, info, warn, error, or fatal. Defaults to error
* `--debug, --verbose` - Set log level to debug, and show log messages on stdout
* `--quiet` - Set log level to error
* `--log-file=FILE` - Path to a file where log messages are written. Defaults to $XDG_CACHE_HOME/brut/logs/brut.log
* `--[no-]log-stdout` - Log messages to stdout in addition to the log file
* `--help, -h` - Show help

## COMMANDS

### [`build-assets`](./brut-cli-commands/build-assets)

Build and manage code and assets destined for the browser, such as CSS, JS, or images
### [`db`](./brut-cli-commands/db)

Manage your database in development, test, and production
### [`deploy`](./brut-cli-commands/deploy)

Deploy your Brut-powered app to production
### [`new`](./brut-cli-commands/new)

Create a Brut App or modify an existing one with new segments
### [`scaffold`](./brut-cli-commands/scaffold)

Create scaffolds of various files to help develop more quckly
### [`test`](./brut-cli-commands/test)

Run and audit tests of the app
