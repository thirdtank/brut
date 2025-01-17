# Handlers

In Brut, a *handler* responds to an HTTP request that *isn't* inteded to render a web page.  Primarily, a handler is used to process a
form submission, but a handler can also respond to an Ajax request.  A handler is like a controller in Rails, however in Brut, a
handler is a class you implement that has a method that receives arguments and a return value that controls the response (unlike controllers in Rails).

## Defining a Route to be Handled

There are three ways to define a route that requires a handler, `form`, `action`, and `path`.

    
    class App < Brut::Framework::App

      routes do

        form   "/new_widget"
        action "/archive_widget/:id"
        path   "/payment_received", method: :get
      end
    end

`form` indicates you have a form you are going to render in HTML and process its submission.  The use of `form` requires that you have
a {Brut::FrontEnd::Form} defined (see {file:doc-src/forms.md}) as well as a handler.  The names are conventional based on the route.
In the example above, Brut will expect `NewWidgetForm` and `NewWidgetHandler` to exist.

You can create these with `bin/scaffold`:

    bin/scaffold form NewWidget

`action` is used when you have a form to submit, but it has no user controlers to collect the data to submit.  This is akin to Rails'
`button_to` where the URL describes everything needed to handle a user's action.  In the example above, you can imagine a form with a
method to `/archive_widget/<%= widget.id %>` that has a button labeled "Archive Widget".  All that's needed is to submit to the
server.

In that case, only a handler is required.  The name is again conventional. In this case, `ArchiveWidgetWithId`.  You can create this
with `bin/scaffold`

    bin/scaffold handler ArchiveWidthWithId

The last case, `path`, is for arbitray routes.  It works the same way as `action`, but requires a `method:` to declare the HTTP
method.

## Implementing a Handler

Regardless of how you declare a route, all handlers must inherit {Brut::FrontEnd::Handler} (though realistically, they will inherit
`AppHandler`, which inherets `Brut::FrontEnd::Handler`) and implement `handle`.

`handle` can accept keyword arguments that are injected by Brut according to the rules outlined in {file:/doc-src/keyword-injection.md Keyword Injection}.  Note that handlers that process forms should declare `form:` as a keyword argument. They will be given an instantiated instance of their form, based on the values in the form submission from the browser.

The return value of the method determines what will happen:

* `URI` - the visitor is redirected to this URI. Typically, you'd achieve this with the {Brut::FrontEnd::HandlingResults#redirect_to}
helper.
* {Brut::FrontEnd::Component} - this component's HTML is rendered. Note that since {Brut::FrontEnd::Page} is a subclass of
`Brut::FrontEnd::Component}, returning a page instance will render that entire page.  This is useful when re-rendering a page with
form errors.
  - You can also return a two-element array with the first element being a component and the second being a `Brut::FrontEnd::HttpStatus`.  This will render the component's HTML but use the given status as the HTTP status.
* {Brut::FrontEnd::HttpStatus} - this status is returned with no content. Typically, you'd achieve this with the {Brut::FrontEnd::HandlingResults#http_status}
* {Brut::FrontEnd::Download} - a file will be downloaded

## Hooks

See {file:/doc-src/hooks.md} for more discussiong, but implementing `before_handle` will allow you to run code before `handle` is
called.  This feature is mostly useful for a base class or module to share re-usable logic.

## Testing Handlers

Since a handler is just a class, you can test it conventionally, but there are a few things to keep in mind that can make testing your
handler easier.

First is that you should call `handle!`, not `handle`.  The public interface of a handler is `handle!`—`handle` is a template method.
`handle!` will call `before_render`, so you should still call `handle!`, even if you are testing the logic in `before_render`.

You can also simplify your expectations with the following matchers:

* `have_redirected_to` - asserts that the handler redirected to the given URL. It can be given a `URI` or a page class.
* `have_rendered`- asserts that the handler renders the given component or page.  It expects the page or component class.
* `have_returned_http_status` - asserts that the handler returned the given HTTP status.  This works for a lot of return values that
the handler can return:
  - If the handler returned a `URI`, the matcher will match on a 302 and fail otherwise
  - If the handler returns an HTTP status code, the matcher's code must match (or the code must be omitted)
  - If the handler returns anything else, the matcher will match on a 200 and fail otherwise

