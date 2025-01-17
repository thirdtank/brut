# JavaScript and Front End Behavior

Brut does not prevent you from using any front-end framework you like.  You can certainly install React and reference it in
`app/src/front_end/javascript/index.js`.  However, Brut would like to humbly request that you not do this.

Brut is based around server-generated HTML and the web platform.  This means that Brut would like you to use custom elements for any
client-side behavior you need, and to do so with progressive enhancement.

To that end, Brut included BrutJS, which is a set of custom elements and ancillary JavaScript you can use to build client-side
behavior.

By default, your `index.js` will look like this:

    import { BrutCustomElements } from "brut-js"
    import Example from "./Example"

    document.addEventListener("DOMContentLoaded", () => {
      BrutCustomElements.define()
      Example.define()
    })

`BrutCustomElements` and `BrutCustomElements.define()` will set up the custom elements bundled with Brut.  `Example` shows you how to
build your own custom elements.

## Some Useful Brut Elements

Please refer to BrutJS's documentation for everything that is included, but here are a few highlights that you will find usefule.

### Client Side Form Support

{file:doc-src/forms.md Forms} outlines Brut's server-side form support.  Brut provides custom elements to allow you to unify client
and server side constraint validations, and make the process a bit easier to manage with CSS.

First, surround a form with a `<brut-form>` will place `data-submitted` onto the `<form>` *only* when the user attempts to submit the
form.  You can use this in your CSS to prevent showing error messages before a user has submitted.

Second, you can use `<brut-cv-messages>` and `<brut-cv>` to control the error messages that are shown when the browser detects
constraint violations.  This works with `<brut-i18n-translation>` to show translated strings.

Consider this ERB

    <label>
      <%= 
        component(
          Brut::FrontEnd::Components::Inputs::TextField.for_form_input(form:, input_name: :name)
        )
      %>
      <span>Name</span>
      <%= constraint_violations(form:,input_name: :name) %>
    </label>

{Brut::FrontEnd::Component::Helpers#constraint_violations} will render the built-in {Brut::FrontEnd::Components::ConstraintViolations}
component.  Along with `for_form_input`, the following HTML will be generated:

    <label>
      <input type="text" name="name" required>
      <span>Name</span>
      <brut-cv-messages input-name="name">
      </brut-cv-messages>
    </label>

When any element of the form causes a validity event to be fired, `<brut-form>` will locate the appropriate `<brut-cv-messages>` and
insert the appropriate `<brut-cv>` elements.  Suppose the user submitted this form. Since the `name` input is required, the form
submission wouldn't happen, and the resulting HTMl would look like so:

    <label>
      <input type="text" name="name" required>
      <span>Name</span>
      <brut-cv-messages input-name="name">
        <brut-cv input-name="name" key="valueMissing"></brut-cv>
      </brut-cv-messages>
    </label>

Now, assuming your layout used `<brut-i18n-translation>` custom elements, for example like so:

    <brut-i18n-translation key="general.cv.fe.valueMissing">%{field} is required</brut-i18n-translation>

The `<brut-cv>` custom element will find this and replace its `textContent`, result in the following HTML:

    <label>
      <input type="text" name="name" required>
      <span>Name</span>
      <brut-cv-messages input-name="name">
        <brut-cv input-name="name" key="valueMissing">
          This field is required
        </brut-cv>
      </brut-cv-messages>
    </label>

You can now use CSS to style client-side validations *and* control the content shown to the user.  If there are server-side constraint
violations, The `ConstraintViolations` component would render them (as well as server-generated translations), for example if a name
was given, but it's taken already, `ConstraintViolations` would render this HTML:

    <label>
      <input type="text" name="name" required value="foo">
      <span>Name</span>
      <brut-cv-messages input-name="name">
        <brut-cv input-name="name" server-side>
          This value has been taken
        </brut-cv>
      </brut-cv-messages>
    </label>

### Confirming Dangerous Actions

Often, you wan to use JavaScript to confirm the submission of a form whose action is considered dangerous to the user or hard to undo.
This can be achieved with `<brut-confirm-submit>`

    <form>
      <input type="text" name="name" required>
      <brut-confirm-submit message="This will delete the app">
        <button>Delete App</button>
      </brut-confirm-submit>
    </form>

By default, this will use the browser's built-in `window.confirm`, however you can also use a `<dialog>` element as well.

If the generated HTML includes a `<dialog>`, you can surround it with `<brut-confirmation-dialog>` to indicate it should be used for
confirmation.  The `<dialog>` should have an `<h1>` where the message will be placed and two buttons, one wiht `value="ok"` and one
with `value="cancel"`.


    <brut-confirmation-dialog>
      <dialog>
        <h1></h1>
        <button value="ok">Do It!</button>
        <button value="cancel">Nevermind</button>
      </dialog>
    </brut-confirmation-dialog>

When the `<brut-confirm-submit>`'s `<button>` is clicked, this `<dialog>` is shown with the message inserted.  If the user hits the
button with `value` of `"ok"`, the form submission goes through. Otherwise, it doesn't.  The dialog is then hidden.

### Ajax Form Submission

To submit a form via Ajax, you can use `<brut-ajax-submit>` around the `<button>` that should submit the form with Ajax.  This element
attempts to provide a fault-tolerante user experience and will set various attributes on itself to allow you to change styling during
the various phases of the request.

If the submission works, it will fire a `brut:submitok` event that your custom code can receive and do whatever makes the most sense
in that case.

If the submission fails with a 422, your server should return a series of `<brut-cv>` custom elements.  If it does, this will be
inserted into the correct `<brut-cv-messages>` elements to dynamically create error messages.  The element will then fire a
`brut:submitinvalid` event you can catch and handle to do something custom.

If the submission times out or fails in some other way, Brut will submit the form the old-fashioned way.

### Client-Side, Accessible Tabs

Many UIs involve a set of tabs that switch between different views.  While HTML has no built-in support for this, Brut's `<brut-tabs>`
custom element can captialize on the various ARIA roles required to design a tabbed interface and provide all the JavaScript behavior
necessary.  See that element's documentation for an extended example.

## Building Your Own Custom Elements

Because custom elements are part of the web platform, Brut encourages you to use them to add client-side behavior.  As a
demonstration of this working, there is an `Example` element set up when you created your app.  Assuming your app's prefix was `cc`
when you created it, the `Example` element works like so:

      <cc-example transform="upper">
        Here is some text
      </cc-example>

When the browser renders this—assuming JavaScript is enabled—it will render the following:

      <cc-example transform="upper">
        HERE IS SOME TEXT
      </cc-example>

You wouldn't want to do this, but this simple element demonstrates both how to make your own and that custom elements in your app are
properly configured.

This element is very close to a vanilla custom element, but it extends `BaseCustomElement`, which is provided by Brut, which includes
z few quality-of-life improvements. Let's walk through the code.

First, we extends `BaseCustomElement` (which extends `HTMLElement`) and define a static attribute, `tagName` that will be the
element's tag name you can use in your HTML:

    import { BaseCustomElement } from "brut-js"

    class Example extends BaseCustomElement {
      static tagName = "cc-example"

Next, we'll define the attributes of our element using `observedAttributes`, which is part of the custom element spec:

      static observedAttributes = [
        "transform",
        "show-warnings",
      ]

The `show-warnings` attribute, if placed on the element's HTML, configures `this.logger` from `BaseCustomElement` to allow output of debug messages. This allows you to easily debug your element's behavior in development, but remove them from production.  We'll see that in a bit.

Next, we'll set a private attribute to hold a default value for the `transform` HTML attribute. It can be named anything:

      #transform = "upper"

Now, we want to know when `transform` changes.  Normally, you'd implement `attributeChangedCallback` and check its `name` parameter.
`BaseCustomElement` allows you to do this more directly by created a `xxxChangedCallback` method for each attribute in
`observedAttributes` that you want to know about.  For `transform`, that means implementing `transformChangedCallback`:

      transformChangedCallback({newValue}) {
        this.#transform = newValue
      }

Next, we implement the bulk of the element's behavior.  Because there are many lifecycle events that may require modifying the
element, `BaseCustomElement` consolidates all of those events and calls the method `update()`.  `update()` should be idempotent
and should examine the element's state (as well as the document's, if necessary) and update the element however it makes sense.

For this example, we want to grab the content, examine the value for `transform` and change the content:

      update() {
        const content = this.textContent
        if (this.#transform == "upper") {
          this.textContent = content.toLocaleUpperCase()
        }
        else if (this.#transform == "lower") {
          this.textContent = content.toLocaleLowerCase()
        }
        else {
          this.logger.info("We only support upper or lower, but got %s",this.#transform)
        }
      }

Notice the last line where we call `this.logger.info`.  If `show-warnings` is omitted from the HTML, this message isn't shown anywhere. If `show-warnings` *is* present, this message will show up in the console.  This can be useful for understanding why your element isn't working.

Lastly, we export the class:

    }
    export default Example

By virtue of having extended `BaseCustomElement`, the static `define()` method will set it up as a custom element with the browser.

## Testing Custom Elements

Sometimes, system tests are sufficient to ensure your custom element code is working.  If not, Brut (via BrutJS) provides a way to
test your element in isolation.

These tests use JSDom which, while not perfect, allows the tests to run reasonably quickly.  Each test begins with `withHTML` to
define the markup that is being tested.  This is followed by `test` which accepts a function that performs the test.

Rather than have a DSL to provide access to your element's state, you can use the browser's API (as provided by JSDom) to check
whatever it is you need to check:

    import { withHTML } from "./SpecHelper.js"

    describe("<cc-example>", () => {
      withHTML(`
      <cc-example>This is some Text</cc-example>
      `).test("upper case by default", ({document,assert}) => {
        const element = document.querySelector("cc-example")
        assert.equal(element.textContent,"THIS IS SOME TEXT")
      })
      withHTML(`
      <cc-example transform="lower">This is some Text</cc-example>
      `).test("lower case when asked", ({document,assert}) => {
        const element = document.querySelector("cc-example")
        assert.equal(element.textContent,"this is some text")
      })
    })

Note that `test`'s second argument—the function that performs the test—is called with objects you can use to perform the test. In this
case, the `document` is passed in as-is the `assert` method.

