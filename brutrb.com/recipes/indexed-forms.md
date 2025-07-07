# Indexed Forms

HTTP allows a form to have any number of elements with the same name.  HTTP will
make all values available to you. Rack supports this, too, but not in a standard
way.

This recipe will show a form that has more than one set of text fields for the same
conceptual field.

## Feature

Allow editing a single form that has 10 sets of name/quantity fields, in order to
bulk create up to 10 widgets at a time.

## Recipe

We'll create a form, a handler, and a page to do this.

### Creating a Form with Indexes

First, we'll scaffold the form and handler:

```
bin/scaffold form /bulk_create_widgets
```

Next, we'll create the form in `app/src/front_end/forms/bulk_create_widgets_form.rb`
This will look like a normal form except each field will have `array: true`, to
indicate there will be an arbitrary number of these fields.  Since they are not all
going to be required, we'll set `required: false`.

When you specify `array:true`, the method created by `input` accepts an index as an
argument. For example,  `form.name(3)` would retrieve the fourth name submitted.

We'll also implement the method `each_widget` that will yield each name/quantity
pair.  The reason Brut doesn't provide this is that your form could have non-array
values as well, so there is no obvious implementation.

Brut *does* provide an `_each` method for every array field. We can use that to
iterate over however many values were submitted.

```ruby
class BulkCreateWidgetsForm < AppForm
  input :name,                    array: true, required: false
  input :quantity, type: :number, array: true, required: false,
                                               min: 1

  def each_widget(&block)
    name_each do |name, index|
      block.(name, self.quantity(index), index)
    end
  end
end
```

### Processing a Form with Array Values

When Brut sends this data to us, each field will be an array of values. We'll see
how to generate the HTML for that in a moment.  Before that, let's implement the
handler.

We want to require a name and quantity if either is present.  If not, it's fine.
When we detect a problem, we'll use the `index:` parameter on
`server_side_constraint_violation` to indicate which index has the issue.

```ruby
# app/src/front_end/handlers/bulk_create_widgets_handledr.rb
class BulkCreateWidgetsHandler < AppHandler
  def initialize(form:)
    @form = form
  end

  def handle
    @form.each_widget(name, quantity, index)
      name_blank     = name.to_s.strip == ""
      quantity_blank = name.to_s.strip == ""
      if name_blank && quantity_blank
        # fine
      elsif !name_blank && !quantity_blank
        # fine
      elsif name_blank
        @form.server_side_constraint_violation(
          input_name: :name,
          key: :required_with_quantity,
          index: index
        )
      else
        @form.server_side_constraint_violation(
          input_name: :quantity,
          key: :required_with_name,
          index: index
        )
      end
    end
    if @form.constraint_violations?
      BulkCreateWidgetsPage.new(form: @form)
    else
      redirect_to(WidgetsPage)
    end
  end
end
```

### Generating a Form with Array Values

Whew!  Now, let's see our HTML for the form. Note the use
of the `index:` parameter when creating the form elements.

```ruby
# app/src/front_end/pages/bulk_create_widgets_page.rb
class BulkCreateWidgetsPage < AppPage

  include Brut::FrontEnd::Components

  def initialize(form:)
    @form = form || BulkCreateWidgetsForm.new
    @num_widgets = 10
  end

  def page_template
    brut_form do
      FormTag(for: @form) do
        @num_widgets.each do |index|
          label do
            Inputs::TextField(form: @form, input_name: :name, index: index)
            div { "Name #{index + 1}" }
            ConstraintViolations(form: @form, input_name: :name, index: index)
          end
          label do
            Inputs::TextField(form: @form, input_name: :quantity, index: index)
            div { "Quantity for Widget #{index + 1}" }
            ConstraintViolations(form: @form, input_name: :quantity, index: index)
          end
        end
        button { "Save Widgets }
      end
    end
  end
end
```

 Even if the form doesn't have 10 entries, the code above will create 10 pairs of
 fields.  If there are server-side constraint violations, they will be shown for the
 appropriate index. Lastly, Brut's components (like `TextField`) will use the Rack
 non-standard HTML for arrays of values. Instead of `name="quantity"`, Brut will
 render `name="quantity[]"`.



