# `brut deploy check`

Check that a deploy can be reasonably expected to succeed


## USAGE

    brut deploy check [options]


## OPTIONS

* `--env=ENVIRONMENT` - Project environment, e.g. test, development, production. Default depends on the command
* `--log-level=LOG_LEVEL` - Log level, which should be debug, info, warn, error, or fatal. Defaults to error
* `--debug, --verbose` - Set log level to debug, and show log messages on stdout
* `--quiet` - Set log level to error
* `--log-file=FILE` - Path to a file where log messages are written. Defaults to $XDG_CACHE_HOME/brut/logs/brut.log
* `--[no-]log-stdout` - Log messages to stdout in addition to the log file
* `--help, -h` - Show help
* `--[no-]check-branch` - If true, requires that you are on 'main' (default true)
* `--[no-]check-changes` - If true, requires that you have committed all local changes (default true)
* `--[no-]check-push` - If true, requires that you are in sync with origin/main (default true)
