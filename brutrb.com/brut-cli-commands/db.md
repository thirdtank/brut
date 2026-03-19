# `brut db`

Manage your database in development, test, and production


## USAGE

    brut db [options] command


## OPTIONS

* `--env=ENVIRONMENT` - Project environment, e.g. test, development, production. Default depends on the command
* `--log-level=LOG_LEVEL` - Log level, which should be debug, info, warn, error, or fatal. Defaults to error
* `--debug, --verbose` - Set log level to debug, and show log messages on stdout
* `--quiet` - Set log level to error
* `--log-file=FILE` - Path to a file where log messages are written. Defaults to $XDG_CACHE_HOME/brut/logs/brut.log
* `--[no-]log-stdout` - Log messages to stdout in addition to the log file
* `--help, -h` - Show help

## COMMANDS

### [`create`](./commands/create)

Create the database if it does not exist
### [`drop`](./commands/drop)

Drop the database if it exists
### [`migrate`](./commands/migrate)

Apply any outstanding migrations to the database
### [`new_migration`](./commands/new_migration)

Create a new migration file
### [`rebuild`](./commands/rebuild)

Drop, re-create, and run migrations, effecitvely rebuilding the entire database
### [`seed`](./commands/seed)

Load seed data into the database
### [`status`](./commands/status)

Check the status of the database and migrations
