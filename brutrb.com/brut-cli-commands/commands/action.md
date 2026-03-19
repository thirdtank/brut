# `brut scaffold action`

Create a handler for an action


## USAGE

    brut scaffold action [options] action_route


## OPTIONS

* `--env=ENVIRONMENT` - Project environment, e.g. test, development, production. Default depends on the command
* `--log-level=LOG_LEVEL` - Log level, which should be debug, info, warn, error, or fatal. Defaults to error
* `--debug, --verbose` - Set log level to debug, and show log messages on stdout
* `--quiet` - Set log level to error
* `--log-file=FILE` - Path to a file where log messages are written. Defaults to $XDG_CACHE_HOME/brut/logs/brut.log
* `--[no-]log-stdout` - Log messages to stdout in addition to the log file
* `--help, -h` - Show help
* `--overwrite` - If set, any files that exists already will be overwritten by new scaffolds
* `--dry-run` - If set, no files are changed. You will see output of what would happen without this flag
* `--http-method=METHOD` - If present, the action will be a path available on the given route and this HTTP method. If omitted, this will create an action available via POST
