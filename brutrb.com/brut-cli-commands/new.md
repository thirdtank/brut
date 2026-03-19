# `brut new`

Create a Brut App or modify an existing one with new segments


## USAGE

    brut new [options] command app_name


## OPTIONS

* `--env=ENVIRONMENT` - Project environment, e.g. test, development, production. Default depends on the command
* `--log-level=LOG_LEVEL` - Log level, which should be debug, info, warn, error, or fatal. Defaults to error
* `--debug, --verbose` - Set log level to debug, and show log messages on stdout
* `--quiet` - Set log level to error
* `--log-file=FILE` - Path to a file where log messages are written. Defaults to $XDG_CACHE_HOME/brut/logs/brut.log
* `--[no-]log-stdout` - Log messages to stdout in addition to the log file
* `--help, -h` - Show help
* `--dir=DIR` - Path where you want your app created. Default is the current directory
* `--app-id=ID` - App identifier, which must be able to be used as a hostname or other Internet identifier. Derived from your app name, if omitted
* `--organization=ORG` - Organization name, e.g. what you'd use for GitHub. Defaults to the app-id value
* `--[no-]interactive` - Set if you want to be prompted before the app is actually created
* `--prefix=PREFIX` - Two-character prefix for external IDs and autonomous custom elements. Derived from your app-id, if omitted.
* `--segments=SEGMENTS` - Comma-delimited list of segment names to add additional behavior to your new app. Current values: heroku, sidekiq, demo
* `--dry-run` - Only show what would happen, don't actually do anything
* `--[no-]demo` - Include, or not, additional files that demonstrate Brut's features (default is true for now)

## COMMANDS

### [`segment`](./commands/segment)

Add a segement to your app to provide additional pre-configured functionality
