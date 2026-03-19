# `brut scaffold component`

Create a new component and associated test


## USAGE

    brut scaffold component [options] ComponentName


## DESCRIPTION

New components go in the `components/` folder of your app, however using --page will create a 'page private' component. To do that, the component name must be an inner class of an existing page, for example HomePage::Welcome. This component goes in a sub-folder inside the `pages/` area of your app


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
* `--page` - If set, this component is for a specific page and won't go with the other components
