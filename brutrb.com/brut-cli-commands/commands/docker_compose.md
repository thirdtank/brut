# `brut deploy docker_compose`

Manage a docker-compose.yml file to be consistent with your deploy config


## USAGE

    brut deploy docker_compose [options] command


## OPTIONS

* `--env=ENVIRONMENT` - Project environment, e.g. test, development, production. Default depends on the command
* `--log-level=LOG_LEVEL` - Log level, which should be debug, info, warn, error, or fatal. Defaults to error
* `--log-file=FILE` - Path to a file where log messages are written. Defaults to $XDG_CACHE_HOME/brut/logs/brut.log
* `--[no-]log-stdout` - Log messages to stdout in addition to the log file
* `--help, -h` - Show help

## COMMANDS

### [`check`](./commands/check)

Check if the existing docker-compose.yml is consistent with the deploy config
### [`generate`](./commands/generate)

Generate or update the existing docker-compose.yml based on current deploy config
