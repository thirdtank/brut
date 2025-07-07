# BrutJS

Brut includes the JavaScript library *BrutJS* which provides HTML custom elements that are useful for
progressively enhancing your HTML.

## Overview

By default, your app is set up to use BrutJS.  This is done by defining all the custom elements it
provides. Their source code is included in your JavaScript bundle, but they do not do anything until you
use one of the custom elements.

Here's what `app/src/front_end/js/index.js` looks like initially:

```javascript
import { BrutCustomElements } from "brut-js"

document.addEventListener("DOMContentLoaded", () => {
  BrutCustomElements.define()
})
``` 

Further, `Brut::FrontEnd::Component` uses Phlex's `register_element` to register all the elements so you
can use them at will in components or pages:

```ruby
def view_template
  form do
    input type: "text", name: "name"
    brut_confirm_submit message: "Are you sure?" do
      button { "Submit" }
    end
  end
end
```

### Custom Elements

The JSDoc for these elements' classes should provide complete documentation, however this is an overview
of what each one does.

| Element                      | Purpose |
|---|---|
| `<brut-ajax-submit>`         | Allows submitting a form via Ajax. Handles the use of `fetch` and all possible cases, but you still provide the logic for what to do with the response. |
| `<brut-autosubmit>`          | Auto submits a form when a `<select>`'s option is chosen.        |
| `<brut-confirmation-dialog>` | Enhances a `<dialog>` to make it easier to use as a generic confirmation with `<brut-confirm-submit>` |
| `<brut-confirm-submit>`      | Uses `window.confirm` or your owned styled `<dialog>` to confirm a button click. |
| `<brut-cv>`                  | Like `<brut-message>` but specific to constraint violations, namely having additional logic for subsituting the field name in the message. |
| `<brut-cv-messages>`         | Wraps `<brut-cv>` elements related to a single form input.        |
| `<brut-copy-to-clipboard>`   | Allows the button inside it to copy text from another element onto the clipboard.        |
| `<brut-form>`                | Manages client-side constraint violation UX unified with the server-side, as well as a few quality-of-life improvements for client-side violations and styling. See [Forms](/forms#forms-and-constraint-violations).|
| `<brut-i18n-translation>`    | Holds the translated value for a single key in the web site visitor's locale.        |
| `<brut-locale-detection>`    | Sends an Ajax request to the server with the browser's reported locale and timezone.  See [space-time continuum](/space-time-continuum#getting-timezone-from-the-browser) for more details.        |
| `<brut-message>`             | Shows a message using an [i18n](/i18n) key to dynamically pull a localized message for client-side constraint violations. |
| `<brut-tabs>`                | Uses ARIA roles related to a tab control and implements it client-side. |
| `<brut-tracing>`             | Sends observability data back to the server to unify a server-side request with client-side tracing.|

> [!NOTE]
> BrutJS's elements were created only to solve specific issues in the apps Brut was initially used for.
> It's hoped that more elements will be added to provide a more feature-complete set of primitives to
> create client-side enhancements.

### Creating Your Own Custom Elements

BrutJS includes a base class, [`BaseCustomElement`](/brut-js/api/BaseCustomElement.html), you can use to
create your own custom elements with a bit more help, but not too much.

The documentation for `BaseCustomElement` has an example, but here are the features you get (noting that
you aren't abandoning the web platform's API, merely gaining a few additional quality-of-life
improvements):

* The ability to add debugging statements that are disabled via markup, not commenting-out `console.log`
* Per-attribute change callbacks so you don't have to create `attributeChangedCallback` as a giant `if/else` block.
* Default implementations of `connectedCallback` and `attributeChangedCallback` that call the template method `update`, thus allowing your element to centralize its logic in one place, regardless of how a state change was triggered.
* Static `define()` method that defines your element based on its static `tagName` field. This allows richer interaction of elements, as you can do e.g. `document.querySelector(SomeOtherElement.tagName)`  and better navigate changes to your code over time.

If you are familiar with the API for autonomous custom elements, `BaseCustomElement` doesn't require
learning much more.  What you know already will be leveraged.

### Removing BrutJS

To remove BrutJS from your app, modify `app/src/front_end/js/index.js` to remove the `import` and call to
`define()`.  You can then remove it from your `package.json`.

> [!NOTE]
> If you remove it like this, several features will not work, including locale detection, client-side observability, and client-side form validation UX.

## Recommnded Practices

### Leaving BrutJS In Your App

BrutJS provides useful tools unrelated to single-page apps, or reactivity, or
whatever else you might be concerned with in your client-side code.  These features
can work alongside whatever framework you want to use. Leave them in unless they are
causing a specific problem.

### You Probably Don't Need a Single-Page App

Consider this decision tree from Alex Russell's [If Not React, Then
What?](https://infrequently.org/2024/11/if-not-react-then-what/):

![Tree showing an SPA decision](/images/spa.png)

This is how Brut wants you to consider your app's architecture.  *Many* apps do not have long-running
sessions where visitors make lots of updates to data.  Most so-called "CRUD" apps do not fall into this
category. The visitor would be better served by a traditional app with server-side HTML generation and
minimal interactivity.  Visitors would also be better served with progressively enhanced features instead
of massive JS payloads that show white screens on low bandwidth/low performance devices.

Thus, Brut recommends you design your app to work in a tranditional multi-page app sort of way, then
*enhance* as needed using autonomous custom elements.

You can, of course, bring in whatever framework you like and use that in the normal way.  BrutJS's custom
elements should work with any framework.

## Testing

See [Testing Custom Elements](/custom-element-tests).

## Technical Notes

> [!IMPORTANT]
> Technical Notes are for deeper understanding and debugging. While we will try to keep them up-to-date with changes to Brut's
> internals, the source code is always more correct.

_Last Updated June 15, 2025_

None.
