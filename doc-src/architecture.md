# Brut's High Level Architecture

Brut attempts to have parity with the web platform in general, and how web browsers work.  For example, a web browser shows you a web
page, thus to do this in Brut, you create a page class.

Brut's core ethos is to captialize on fundamental knowledge you must already posses to build a web app, such as HTML, JavaScript, the
Web Platform, SQL, etc.

The best way to understand Brut is to break down how a request is handled.

## HTTP Requests at a High Level

1. HTTP Request is received
2. If the request's route is mapped, handle it and return the result
3. Otherwise, 404

This pretty much describes every web app server in the world.  Let's dig into step 2

## Pages, Forms, Actions

HTML allows for exactly two ways to interact with a server: Issuing a `GET` for a resource (like a web page), or submitting a form via
a `GET` or `POST`.

1. HTTP Request is received
2. If the route is a mapped page, render that page
3. If the route is a configured form, submit that form handle it
4. If the route is an asset like CSS or an image, send that.
5. Otherwise, 404

A browser can use JavaScript to submit other requests, and Brut handles those, too:

1. HTTP Request is received
2. If the route is a mapped page, render that page (See {file:doc-src/pages.md})
3. If the route is a configured form, submit that form handle it (See {file:doc-src/forms.md})
4. If the route is a configured action, perform it and return the results. (See {file:doc-src/handlers.md})
5. If the route is an asset like CSS or an image, send that. (See {file:doc-src/assets.md})
6. Otherwise, 404

Before we dig deeper, it's worth pointing out at this point that *Brut is not an MVC framework*, mostly because there are no
controllers.  *Models* in the MVC sense are instead *pages* or *components*—classes that provide all dynamic behavior and data needed
to render some HTML.  Brut uses ERB templates to generate HTML and you could think of this as the view, if you want.


