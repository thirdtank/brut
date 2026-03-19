# `brut build-assets images`

Copy images to the public folder


## USAGE

    brut build-assets images [options]


## DESCRIPTION

This is to ensure that any images your code references will end up in the public directory, so they are served properly. This is not for managing images that may be referenced in CSS files. See the `css` command for information on that.


## OPTIONS

* `--env=ENVIRONMENT` - Project environment, e.g. test, development, production. Default depends on the command
* `--log-level=LOG_LEVEL` - Log level, which should be debug, info, warn, error, or fatal. Defaults to error
* `--debug, --verbose` - Set log level to debug, and show log messages on stdout
* `--quiet` - Set log level to error
* `--log-file=FILE` - Path to a file where log messages are written. Defaults to $XDG_CACHE_HOME/brut/logs/brut.log
* `--[no-]log-stdout` - Log messages to stdout in addition to the log file
* `--help, -h` - Show help
* `--[no-]clean` - If set, any old files from previous runs are deleted. Defaults to false in production, true everywhere else.
