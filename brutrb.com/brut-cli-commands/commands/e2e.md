# `brut test e2e`

Run end-to-end (browser) tests


## USAGE

    brut test e2e [options] specs_to_run...


## DESCRIPTION

Runs all end-to-end tests for the app, or runs a subset of end-to-end tests using RSpec-style syntax. This will run bin/test-server first, so if that fails for some reason, no tests are run.


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

## ENVIRONMENT VARIABLES

* `E2E_RECORD_VIDEOS` -  If set to 'true', videos of each test run are saved in `./tmp/e2e-videos`
* `E2E_SLOW_MO` -  If set to, will attempt to slow operations down by this many milliseconds
* `E2E_TIMEOUT_MS` -  ms to wait for any browser activity before failing the test. And here you didn't think you'd get away without using sleep in browse-based tests?
* `LOGGER_LEVEL_FOR_TESTS` -  Can be set to debug, info, warn, error, or fatal to control logging during tests. Defaults to 'warn' to avoid verbose test output
* `RSPEC_PROFILE_EXAMPLES` -  If set to any value, it is converted to an int and set as RSpec's number of examples to profile. NOTE: this is used in the app's spec_helper.rb so could've been removed
* `RSPEC_WARNINGS` -  If set to 'true', configures RSpec warnings for the test run. NOTE: this is used in the app's spec_helper.rb so could've been removed
