# `brut test`

Run and audit tests of the app


## USAGE

    brut test [options] command


## OPTIONS

* `--env=ENVIRONMENT` - Project environment, e.g. test, development, production. Default depends on the command
* `--log-level=LOG_LEVEL` - Log level, which should be debug, info, warn, error, or fatal. Defaults to error
* `--debug, --verbose` - Set log level to debug, and show log messages on stdout
* `--quiet` - Set log level to error
* `--log-file=FILE` - Path to a file where log messages are written. Defaults to $XDG_CACHE_HOME/brut/logs/brut.log
* `--[no-]log-stdout` - Log messages to stdout in addition to the log file
* `--help, -h` - Show help
* `--[no-]rebuild` - If true, test database is rebuilt before tests are run (default false)
* `--[no-]rebuild-after` - If true, test database is rebuilt after tests are run (default false)
* `--seed=SEED` - Set the random seed to allow duplicating a test run

## COMMANDS

### [`audit`](./commands/audit)

Audits all of the app's classes to see if test files exist
### [`e2e`](./commands/e2e)

Run end-to-end (browser) tests

Runs all end-to-end tests for the app, or runs a subset of end-to-end tests using RSpec-style syntax. This will run bin/test-server first, so if that fails for some reason, no tests are run.
### [`js`](./commands/js)

Run JavaScript unit tests

Runs all JavaScript unit tests for the app. This does not support running individual tests.
### [`run`](./commands/run)

Run non-e2e tests

Runs all non end-to-end tests for the app, or runs a subset of non-end-to-end tests using RSpec-style syntax. Do note that you cannot use this command to run an end-to-end test, since those require the test server to be running.
