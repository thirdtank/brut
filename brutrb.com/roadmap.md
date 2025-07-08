# Roadmap to 1.0

A lot of Brut is solid, but there's several things missing from what I would
call a 1.0 release.  Here are some ideas of what I think is needed:

## Better Dev Experience

* The output of `bin/dev` isn't great.
* otel-desktop-viewer is cool, but not the easiest to figure out issues as compred to good 'ole logging.
* Error pages in the app are *really* bad.
* CLI apps are OK, but could be fancier.

## More Tests

* Unit tests for all/most classes are needed. There's only a few now.
* Integration test of `mkbrut`, all automated.
* Web component/custom element tests need to be re-thought.
* Test output is a wall of text stack trace and this sucks.
* Improvements in access to Playwright features.
* Playright is the worst E2E testing tool except all the rest. Would love a better option here.

## More Complete Web Features

* Content security policy doens't allow for hashes, which can be limiting in some situations. I want everyone to be running with a CSP, so it has to be configurable to some degree.
* Websockets, server-push, etc. should be possible or at least have a recipe.
* Learn more about importmaps.

## Client-Side Improvements

BrutJS is woefully incomplete.  I'd like developers to be able to accomplishe
certain tasks without needing a framework:

* Hooks into asset building to e.g. enable TailwindCSS or other tools.
* Better use of `fetch` in more situations
* Server-generated HTML replacement
* Better support for "API" style back-end when a framework *is* going to be used.

## Deployment

Out of the box support for more deployment mechanism, at least:

* Normal Heroku/`Procfile`-based deploy
* Digital Ocean-style hosting
* VPS?

## Documentation

* More recipes for how to do things
* More complete API docs with examples
* A unified look and feel across the board
* Get rid of VitePress for something less client-heavy, but still great
* Dash-accessible API docs

## Misc

* More direct Sidekiq support

