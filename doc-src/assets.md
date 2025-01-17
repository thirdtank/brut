# Assets - CSS, JavaScript, Images

To learn about Brut's JavaScript API support, see {file:doc-src/javascript.md}. This page is about how requests for assets are
managed.

At a high level, all assets are served out of the *public folder*, which is in `app/public`.  Brut copies files into this folder as
part of the build and development process.

Currently, Brut supports JavaScript, CSS, Fonts, and Images.  These are all copied and/or processed from a source location into
`app/public` via {Brut::CLI::Apps::BuildAssets}:

* JavaScript - From `app/src/front_end/js`, bundled to `app/public/js`.
* CSS - From `app/src/front_end/css`, bundled to `app/public/css`.
* Fonts - From `app/src/front_end/fonts`, bundled to `app/public/css` (yes, they are bundled to `css` as that is the only reason to have a built step for fonts - see below).
* Images - From `app/src/front_end/iamges` to `app/public/images`.

## Images

Images are the simplest.  Images in Brut are not hashed, so they are essentially synced from `app/src/front_end/images` to
`app/public/images`.  Your CDN should arrange for cache invalidation.

## SVGs

SVGs are treated specially.  They are located in `app/src/front_end/svgs`.  To use an svg, your ERB should use the
{Brut::FrontEnd::Component::Helpers#svg} to inline the SVG into the page.  You can put SVGs intended to be linked-to in
`app/src/front_end/images`, but for SVGs to be used as icons, for example, place them in `app/src/front_end/svgs` and use the `svg`
helper.

## JavaScript

JavaScript is currently managed by ESBuild.  No fancy options are used nor currently possible.  By default, there is a single entry
point for all your JavaScript, located in `app/src/front_end/javascript/index.js`.  This is compiled into `app/public/js/app-«HASH».js`, for example `app/public/js/app-EAALH2IQ.js`. A sourcemap is included.  Third party JS can be referenced and is assumed to be in `node_modules`.

This should be sufficient for most apps, however you can use additional entry points. See {file:doc-src/javascript.md} for how to set
this up. Also see "Hashing" below for how hashing works and is managed.

## CSS

CSS is also managed by ESBuild.  There is a single entry point located in `app/src/front_end/css/index.css`, and this is compiled into
`app/public/css/styles-«HASH».css`, for example `app/public/css/styles-EAALH2IQ.css`. A sourcemap is included. Third party CSS can be
referenced and is assumed to be in `node_modules`.

Currently, there is no support for multiple CSS entry points - your entire app's CSS is expected to be in (or referenced by)
`index.css`.

To do that, Brut assumes you will use standard APIs, namely `@import`, and this is how you can bring in third party CSS as well as to
manage your app's CSS in multiple files:

    @import "bootstrap/index.css";
    @import "colors.css";

    html { font-size: 20px; }

## Fonts

ESBuild will handle fonts when CSS is built.  Fonts are hashed.  You should place fonts in `app/src/front_end/fonts`, however this is
merely a convention.  ESBuild will find your font as long as you properly use `url(...)` to reference it.

To follow the convention, here is how you might write your CSS:

    /* index.css */
    @font-face {
      font-family: "Monaspace Xenon";
      src: url("../fonts/monaspace-xenon.ttf") format("truetype");
      font-display: swap;
    }

ESBuild treats the relative path in `url` as relative to where the file being procssed is, thus it will expect to find
`app/src/front_end/fonts/monaspace-xenon.ttf`.  While it's not relevant to you where it's copied, the file will be hashed and copied
to `app/public/css` and the `url(..)` will be adjusted, for example:

    @font-face {
      font-family: "Monaspace Xenon";
      src: url("./monaspace-xenon-VZ5IIHXZ.ttf") format("truetype");
      font-display: swap;
    }

## Hashing

Hashing is on in development, testing, and production, as a way to minimize differences between the three environments.  The way Brut
manages this is via the file `app/config/asset_metadata.json`.  This file maps the logical name of an asset to its hashed name. For
example:

    {
      "asset_metadata": {
        ".js": {
          "/js/app.js": "/js/app-L6VPFHLG.js"
        },
        ".css": {
          "/css/styles.css": "/css/styles-PHUHEJY3.css"
        }
      }
    }

{Brut::FrontEnd::Component::Helpers#asset_path} accepts the logical name (`/js/app.js`) and returns the actual name
`/js/app-L6VPFHLG.js`).  `asset_metadata.json` is managed by `bin/build-assets`.

Note that the fonts are not present in this file since they are only needed by CSS, and ESBuild handles the translation there.
