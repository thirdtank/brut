# Forms

Brut's form support is designed to have parity with the Web Platform and allow you to both generate HTML and pasrse the results of a
form submission from a single source of truth.  Brut's forms also allow the unification of client-side and server-side constraint
violations so that you can provide client-side validations but not require JavaScript for all validations.

## High Level Overview of Forms

The purpose of a form is to allow the website visitor to submit data to you.  The Web Platform and web browser have deep support for
this, but the core way this works is that you have a `<form>` element that contains form elements like `<input>` or `<select>` elements and, when this form is submitted, your server can access the values of each element and take whatever action is necessary.

The lifecycle of this process looks like so:

1. HTML is generated, including a form with elements based on a definition you provide.
2. The visitor submits the form.
3. If there are constraint violations that the browser can detect, the form will not be submitted to your server.
4. If all constraints are satisfied (or the visitor bypasses client-side constraints), the server receives the form submission.
5. A {Brut::FrontEnd::Handler} is triggered to process that submission.  The handler should re-check the client-side constraints and
   can perform further server-side checks.
6. The handler will decide what the website visitor will experience next (e.g. re-render the form, proceed to another page, etc).

As a developer, you must write four pieces of code:

* Call {Brut::SinatraHelpers::ClassMethods.form} to declare the route.
* Create a subclass of {Brut::FrontEnd::Form} (whose name is determined by the route name). This class declares the inputs of your
form.
* Create a subclass of {Brut::FrontEnd::Handler} (whose name is determined by the route name). This class processes the form.
* ERB to generate the form.  The classes in {Brut::FrontEnd::Components::Inputs} have methods like {Brut::FrontEnd::Components::Inputs::TextField.for_form_input} that will generate HTML for you.

## Concepts

Brut tries to create concepts that have a direct analog to the web platform.

These basic concepts form the basis for Brut's form support:

* *Form* is an HTML `<form>`
* *Input* is an HTML `<input>`, `<select>`, `<textarea>`, etc.
* *Input Name* is the name of an input, as defined by the `name` attribute.
* *Submitting a form* is when the browser submits a form to the form's action. This is done with an HTTP GET or HTTP POST only. No
other HTTP methods can submit a form.
* *Constraint Violation* describes invalid data in an input.

Building on these, Brut specifies how it manages Forms, Inputs, and Submission:

* *Form Class* defines the inputs a specific form will have.
* *Input Definition* defines the input for a given input name.
* *Form Object* holds the values and constraint violations of all inputs.
* *Handler* is a class that processes a form submission. It's `handle!` method can access the Form Object representing a submission.
* *Server-Side Constraint Violation* describes invalid data that required server processing to determine.

## Basic Workflow for Handling a Form

### Define Your Form

In Brut, a *form* class (or *form object*) holds metadata about the form in question. Namely, it defines all of the inputs and any
client-side constraints. For example, here is a form to create a new widget, where the name must be at least 3 characters and is
required, and there is an optional description:

    class NewWidgetForm < AppForm
      input :name, minlength: 3
      input :description, required: false
    end

This form class provides a few features:

* It can be used to generate HTML. For example, the "name" field will generate `<input type="text" name="name" required minlength="3">`
* It holds the data submitted to the server, serving as an allowlist of which parameters are accepted. For example, if the browser
submits "name", "description", and "price", since "price" is not an input of this form, the server will discard that value. Your code
will only have access to "name" and "description"
* It can validate the client-side constraints on the server.  If a visitor submits the form, bypassing client-side constraint
validations, and "name" is only two characters, the form object will see that the "name" field has a violation.

### Define Your Handler

Handlers are like controller methods in Rails - they receive the data from a request and process it.  Unlike a Rails controller, a
Handler is a normal class. It implements the method `handle!`.  The method signature you use for `handle!` determines what data will
be passed into it.  The return value of `handle!` determines what happens after processing is complete.

Suppose that creating a widget requires that the name be unique.  If it's not, we re-render the page containing the form and show the
user the errors.  Suppose that the page in question is `/new_widget`, which would be the class `NewWidgetPage`.

    class NewWidgetHandler < AppHandler
      def handle!(form:)
        if !form.constraint_violations?
          if DB::Widget[name: form.name]
            form.server_side_constraint_violation(input_name: :name, key: :not_unique)
          end
        end

        if form.constraint_violations?
          return NewWidgetPage.new(form:)
        end

        DB::Widget.create(name: form.name, description: form.description)
        redirect_to(WidgetsPage)
      end
    end
         

{file:doc-src/pages.md Pages} provides more information about what `NewWidgetPage` and `WidgetsPage` might be or do, but the logic in
the handler is, hopefully, clear.  If our form is free of client-side constraint violations, we check to see if there is another
widget with the name from the form. If there is, we set a server-side constraint violation.

After that, if the form has any constraint violations (server-side or client-side), we return `NewWidgetPage` initialized with our
existing form.  This will allow that page to generate HTML that includes information about the constraint violations detected.

If there aren't constraint violations, we create a widget in the database, then redirect to `WidgetsPage`.  {Brut::FrontEnd::HandlingResults#redirect_to} is a convienience method for figuring out the URL for a given page.

### Generate HTML

In this example, `NewWidgetPage` would be generating the HTML form.  It's class might look like so:

    class NewWidgetPage < AppPage

      attr_reader :form

      def initialize(form: nil)
        @form ||= NewWidgetForm.new
      end
    end

Here is the most direct way to use the form object to render HTML.

      <%= form_tag for: form do %>
        <%= component(Brut::FrontEnd::Components::TextField.for_form_input(form:, input_name: :name)) %>
        <%= component(Brut::FrontEnd::Components::Textarea.for_form_input(form:, input_name: :description)) %>
        <button>Save</button>
      <% end %>

`for_form_input` uses the metadata in the form, along with the name of the field, to generate the appropriate HTML.  This will only
generate an `<input>` tag, so you have complete flexibility to style it however you like.

You can also use `constraint_violations` to render any errors:

      <%= form_tag for: form do %>

        <%= component(Brut::FrontEnd::Components::TextField.for_form_input(form:, input_name: :name)) %>
        <%= constraint_violations(form:, input_name: :name) %>

        <%= component(Brut::FrontEnd::Components::Textarea.for_form_input(form:, input_name: :description)) %>
        <%= constraint_violations(form:, input_name: :description) %>

        <button>Save</button>
      <% end %>

## Multiple Inputs with the Same Name

The HTTP spec allows for any number of inputs with the same name. All values are submitted.  Rack, upon which Brut is based, further
provides a way to access such duplicate names as an array, using a naming convention.

Brut forms support this via `array: true` when defining an input:

    class NewWidgetForm < AppForm
      input :name, minlength: 3, array: true
      input :description, required: false, array: true
    end

When you do this, a call to `for_form_input` will require an index, as will any other method you use to interact with the form, such
as `server_side_constraint_violation`.  When the HTML is generated, the `name=` of the `<input>` will use Rack's naming convention:

    <input type="text" name="name[]" ...>

To access the values, you can pass an index to the generated method name, or use the `_each` form:

    def handle!(form:)
      form.name(1) # get the second value for the 'name' input
      form.name_each do |value,i|
        value # is the value of the input, empty string if omitted
        i     # is the zero-based index
      end
    end

When generating HTML, the form object will generate any number of inputs that you request:

      <%= form_tag for: form do %>

        <% 10.times do |index| %>
            <%= component(Brut::FrontEnd::Components::TextField.for_form_input(form:, input_name: :name, index:)) %>
            <%= constraint_violations(form:, input_name: :name) %>
        <% end %>

        <button>Save</button>
      <% end %>

## Styling and Client-Side Behavior

While browsers have long-supported client-side constraint validations, there are a few complications that make them hard to use in
practice.  Brut provides solutions for most of these issues and allows you to unify your error reporting into a single user experien
ce, regardless of where the constraint violation was identified. This does, however, require JavaScript.  But, it is entirely opt-in.

### Issue: Blank Forms Match `:invalid` Pseudo-Class

If an input is required, it will match the `:invalid` pseudo class if it has no value, even if a user has not interacted with the
input.  While Brut cannot change this behavior, it *does* allow you to have better control.

If you surround your `<form>` with the `<brut-form>` custom element, that element will add `data-submitted` to the `<form>` element
when submission is attempted. This means that your CSS can target something like `form[data-submitted] input:invalid` so that any
styling for constraint violations will only show up if the user has attempted to submit the form.

### Issue: App-Controled Messaging for Client-Side Constraint Violations

While it's not currently possible to control the browser's UI around client-side constraint violations, Brut does allow you to provide
your own error messages and UX when this happens. This means you can unify your client-side and server-side messaging so it looks the
same no matter what.

When a field is detected to be invalid, `<brut-form>` will locate a `<brut-cv-messages>` custom element and provide it with the
`ValidityState` of the input. This will create one `<brut-cv>` custom element for each constraint violation.  The `<brut-cv>` custom
element will use its `key=` attribute to locate the appropriate `<brut-i18n-translation>` custom element, which your server should've
rendered with the appropriate error messages.

This has the effect of inserting a localized message you control into the DOM wherever you want it for reporting the error to the
user.


