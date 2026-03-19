# `brut deploy build`

Build a series of Docker images from a template Dockerfile


## USAGE

    brut deploy build [options]


## OPTIONS

* `--env=ENVIRONMENT` - Project environment, e.g. test, development, production. Default depends on the command
* `--log-level=LOG_LEVEL` - Log level, which should be debug, info, warn, error, or fatal. Defaults to error
* `--debug, --verbose` - Set log level to debug, and show log messages on stdout
* `--quiet` - Set log level to error
* `--log-file=FILE` - Path to a file where log messages are written. Defaults to $XDG_CACHE_HOME/brut/logs/brut.log
* `--[no-]log-stdout` - Log messages to stdout in addition to the log file
* `--help, -h` - Show help
* `--platform=PLATFORM` - Override default platform. Can be any Docker platform.
* `--dry-run` - Only show what would happen, don't actually do anything
* `--skip-checks` - If true, skip pre-build checks (default )
