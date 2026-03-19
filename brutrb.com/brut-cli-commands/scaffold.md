# `brut scaffold`

Create scaffolds of various files to help develop more quckly


## USAGE

    brut scaffold [options] command


## OPTIONS

* `--env=ENVIRONMENT` - Project environment, e.g. test, development, production. Default depends on the command
* `--log-level=LOG_LEVEL` - Log level, which should be debug, info, warn, error, or fatal. Defaults to error
* `--debug, --verbose` - Set log level to debug, and show log messages on stdout
* `--quiet` - Set log level to error
* `--log-file=FILE` - Path to a file where log messages are written. Defaults to $XDG_CACHE_HOME/brut/logs/brut.log
* `--[no-]log-stdout` - Log messages to stdout in addition to the log file
* `--help, -h` - Show help

## COMMANDS

### [`action`](./commands/action)

Create a handler for an action
### [`base_command`](./commands/base_command)


### [`component`](./commands/component)

Create a new component and associated test

New components go in the `components/` folder of your app, however using --page will create a 'page private' component. To do that, the component name must be an inner class of an existing page, for example HomePage::Welcome. This component goes in a sub-folder inside the `pages/` area of your app
### [`custom_element_test`](./commands/custom_element_test)

Create a test for a custom element in your app
### [`db_model`](./commands/db_model)

Creates a DB models, factories, and a single placeholder migration

Creates empty versions of the files you'd need to access a database table or tables, along with a migration to, in theory, create those tables. Do note that this will guess at external id prefixes
### [`e2e_test`](./commands/e2e_test)

Create the shell of an end-to-end test
### [`form`](./commands/form)

Create a form and handler
### [`page`](./commands/page)

Create a new page and associated test
### [`test`](./commands/test)

Create the shell of a unit test based on an existing source file
