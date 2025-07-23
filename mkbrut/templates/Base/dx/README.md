# Workspace Commands

These commands manage the Workspace, AKA the part of the development environment that
runs on your computer (sometimes called the *host*).

These are all written in Bash as that is the only environment that can be relied upon to exist on any operating system.

These are designed to be somewhat agnostic of your app and Brut may update some of
these files if changes are needed.  All app-specific configuration is consolidated
into just a few files.

These files are owned by Brut and you should avoid editing them:

* `bash_customizations` - Bash configuration
* `build` - Builds the development docker image
* `dx.sh.lib` - Shared bash functions
* `exec` -  Run commands inside a container
* `prune` - Remove unused containers
* `README.md` - This file
* `show-help-in-app-container-then-wait.sh` - Runs inside the app container to keep
the container up
* `start` - starts the Workspace/dev environment
* `stop` - stops the Workspace/dev environment

These files contain project-specific information and Brut will not change them:

* `docker-compose.env` - Configuration values.
* `bash_customizations.local` - Per-developer bash configuration, **project specific**, **developer specific**, **do not check into version control**.
