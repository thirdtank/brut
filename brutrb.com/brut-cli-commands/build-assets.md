# `brut build-assets`

Build and manage code and assets destined for the browser, such as CSS, JS, or images


## USAGE

    brut build-assets [options] command


## OPTIONS

* `--env=ENVIRONMENT` - Project environment, e.g. test, development, production. Default depends on the command
* `--log-level=LOG_LEVEL` - Log level, which should be debug, info, warn, error, or fatal. Defaults to error
* `--debug, --verbose` - Set log level to debug, and show log messages on stdout
* `--quiet` - Set log level to error
* `--log-file=FILE` - Path to a file where log messages are written. Defaults to $XDG_CACHE_HOME/brut/logs/brut.log
* `--[no-]log-stdout` - Log messages to stdout in addition to the log file
* `--help, -h` - Show help

## COMMANDS

### [`all`](./commands/all)

Build all assets
### [`css`](./commands/css)

Builds a single CSS file suitable for sending to the browser

This produces a hashed file in every environment, in order to keep environments consistent and reduce differences. If your CSS file references images, fonts, or other assets via `url()` or other CSS functions, those files will be hashed and copied into the output directory where CSS is served.

 To ensure this happens correctly, your `url()` or other function must reference the file as a relative file from where your actual source CSS file is located. For example, a font named `some-font.ttf` would be in `app/src/front_end/fonts`. To reference this from `app/src/front_end/css/index.css` you'd use `url("../fonts/some-font.ttf")`
### [`images`](./commands/images)

Copy images to the public folder

This is to ensure that any images your code references will end up in the public directory, so they are served properly. This is not for managing images that may be referenced in CSS files. See the `css` command for information on that.
### [`js`](./commands/js)

Builds and bundles JavaScript destined for the browser
