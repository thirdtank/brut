# `brut test audit`

Audits all of the app's classes to see if test files exist


## USAGE

    brut test audit [options]


## OPTIONS

* `--env=ENVIRONMENT` - Project environment, e.g. test, development, production. Default depends on the command
* `--log-level=LOG_LEVEL` - Log level, which should be debug, info, warn, error, or fatal. Defaults to error
* `--debug, --verbose` - Set log level to debug, and show log messages on stdout
* `--quiet` - Set log level to error
* `--log-file=FILE` - Path to a file where log messages are written. Defaults to $XDG_CACHE_HOME/brut/logs/brut.log
* `--[no-]log-stdout` - Log messages to stdout in addition to the log file
* `--help, -h` - Show help
* `--ignore=PATH[,PATH]` - Ignore any files in these paths, relative to app root
* `--type=TYPE` - Only audit this type of file
* `--show-scaffold` - If set, shows the command to scaffold the missing tests
