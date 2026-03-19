# `brut deploy`

Deploy your Brut-powered app to production


## USAGE

    brut deploy [options] command


## OPTIONS

* `--env=ENVIRONMENT` - Project environment, e.g. test, development, production. Default depends on the command
* `--log-level=LOG_LEVEL` - Log level, which should be debug, info, warn, error, or fatal. Defaults to error
* `--debug, --verbose` - Set log level to debug, and show log messages on stdout
* `--quiet` - Set log level to error
* `--log-file=FILE` - Path to a file where log messages are written. Defaults to $XDG_CACHE_HOME/brut/logs/brut.log
* `--[no-]log-stdout` - Log messages to stdout in addition to the log file
* `--help, -h` - Show help

## COMMANDS

### [`build`](./commands/build)

Build a series of Docker images from a template Dockerfile
### [`check`](./commands/check)

Check that a deploy can be reasonably expected to succeed
### [`heroku`](./commands/heroku)

Deploy to Heroku using container-based deployment
