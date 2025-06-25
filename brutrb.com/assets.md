# Assets

As mentioned in [Javascript](/javascript) and [CSS](/css), esbuild is used to bundle JavaScript and CSS. Brut also provides support for managing images.

## JavaScript and CSS

Both JavaScript and CSS are managed largely the same way: esbuild is given `app/src/front_end/js/index.js` or
`app/src/front_end/css/index.css` and a bundle is produced.

For both JS and CSS, the bundles are *hashed*, even in development.  This is to reduce differences in production
and development.  The `asset_path` helper can translate the logical path (`/js/app.js` or `/css/styles.css`) into
the specific hashed path.

Sourcemaps are provided as well, for both development and production.

### What is Hashing and Why Do It?

In production, while your pages produce dynamic data, the CSS and JavaScript bundles themselves are not dynamic.
They are the same for every single request until you change them. Because of this, it's common to configure a
cache for these files. Often, that cache is a *content delivery network* or CDN.

When a page is rendered, the browser will ask for the CSS and JS bundles. The CDN will tell the browser it's
OK to cache the file, potentially for a very long time (years).  On subsequent requests for those files, the
browser will re-use its cached copy, saving bandwidth and time.

A downside of this approach is when you *do* want to change something.  While most CDNs allow you to invalidate
their cached values, there are many layers of caching whose behavior can be hard to control.  It turns out to be
much simpler to rename the file each you change it, thus "breaking the cache".

A common way to do this is to create a hash of the file's contents and append that value to its name, so instead
of `/static/css/styles.css`, the file would `/static/css/styles-98724fhjkjk.css`.  When you make a change to
your CSS, it'll get new name, say `/static/css/styles-3yjgdrjksrfdws.css`.

To keep you from having to deal with this directly, Brut's `asset_path` helper will translate a logical name like
`/css/styles.css` to the actual name, like `/static/css/styles-3yjgdrjksrfdws.css`.

### What are SourceMaps and Why Create Them?

Bundled JavaScript and CSS will have been *minified*.  This means removing whitespace, line breaks and, in the
case of JavaScript, potentially changing the actual names of classes and variables.  This is all to reduce the
size of the file as much as possible without changing its meaning.

In your browser's dev tools, all your CSS is one the first line of `styles.css` and every stack trace from your
JavaScript is on line 1 of `app.js`.  This is not helpful for diagnosing issues.

*SourceMaps* are separate files that translate the minified files back to normal ones, so you can see a normal
stack trace with the actual line numbers of your source files.

There are many ways to create source maps and if you've used a tool like WebPack, you'll recall that many of them
don't produce usable source maps.  Brut uses esbuild's facility for this, with a focus on correctness. When
you see a line number and a source file in your browser, you can be sure it's accurate.

The tradeoff is that it can take longer to produce than producing an inaccurate one. I'm not sure who wants
inaccurate source maps, but Brut does not support this. In practice, esbuild is quite fast, so it should not make
a practical difference in your day to day work.


## Fonts

Custom fonts are managed implicitly by esbuild's managing of CSS.  In your CSS, you should reference fonts as
relative to the CSS file.  For example, if you have the font `app/src/front_end/fonts/monaspace-xenon.ttf`, then
your `app/src/front_end/css/index.css` should look like so:

```css {3}
@font-face {
  font-family: "Monaspace Xenon";
  src: url("../fonts/monaspace-xenon.ttf") format("truetype");
  font-display: swap;
}
```
When CSS is bundled, esbuild will copy and hash the fonts, then rewrite the CSS to reference them.

Brut does not support font management in any other way.

## Images

Brut supports managing images, and will `rsync` them from `app/src/front_end/images` to
`app/public/static/images`, where you can reference them via `/static/images/«image_name»`.

Brut does not support hashing of image names.

You can reference images like so:

```ruby
def view_template
  div do
    # Renders app/src/front_end/images/foo.png
    img src: "/static/images/foo.png", alt: "Picture of a foo"
  end
end
```

## SVGs

You can place `.svg` files in `app/src/front_end/images` if you wish to use them in `<img>` tags.  However, if
you place svgs in `app/src/front_end/svgs`, they can be inlined into your HTML via `inline_svg`.  In this case,
there is no need for a build step, since the SVG source is included directly in your HTML. This works well
for icons.

## `favicon.ico`

`Brut::FrontEnd::Middlewares::Favicon` is configured by default to handle requests for `/favicon.ico`.  It
returns a 301 to `/static/images/favicon.ico`. This means that Brut expects
`app/src/front_end/images/favicon.ico` to exist.


## All Other Assets

Brut currently does not support any other managed asset. However, you can place files in `app/public/static` and
they will be served up directly.


## Technical Notes

> [!IMPORTANT]
> Technical Notes are for deeper understanding and debugging. While we will try to keep them up-to-date with changes to Brut's
> internals, the source code is always more correct.

_Last Updated May 7, 2025_

`bin/build-assets` manages all of the behavior described on this page.  `bin/build-assets css` and
`bin/build-assets js` modify the file `app/config/asset_metadata.json`, which stores the mappings between logic
paths and hashed paths:

```json
{
  "asset_metadata": {
    ".js": {
      "/js/app.js": "/js/app-7MMIZXTZ.js"
    },
    ".css": {
      "/css/styles.css":"/css/styles-ZAISBLGE.css"
    }
  }
}
```

As you can see, this format could support multiple bundles and additional file types.
