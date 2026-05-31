# `brut deploy`

Deploy your Brut-powered app to production


## USAGE

    brut deploy [options] command


## OPTIONS

* `--env=ENVIRONMENT` - Project environment, e.g. test, development, production. Default depends on the command
* `--log-level=LOG_LEVEL` - Log level, which should be debug, info, warn, error, or fatal. Defaults to error
* `--log-file=FILE` - Path to a file where log messages are written. Defaults to $XDG_CACHE_HOME/brut/logs/brut.log
* `--[no-]log-stdout` - Log messages to stdout in addition to the log file
* `--help, -h` - Show help

## COMMANDS

### [`docker`](./commands/docker)

Build one docker image to use for all commands in production
### [`docker_compose`](./commands/docker_compose)

Manage a docker-compose.yml file to be consistent with your deploy config
### [`heroku`](./commands/heroku)

Deploy to Heroku using container-based deployment
