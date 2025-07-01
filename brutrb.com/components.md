# Components

Components in Brut are Phlex Components: a class that can hold data and use that to generate HTML.  Components are the primary way you achieve re-use of markup or view logic.

## Overview

`Brut::FrontEnd::Component` inherits from `Phlex::HTML`, which means that to create a component you must do three things:

1. Create a class in `app/src/front_end/components` that inherites from `AppComponent` (which is part of your app and inherits from `Brut::FrontEnd::Component`)
2. Implement an initializer that receives anything your component needs to do its job.  It is recommended (but not required) that your initializer use only keyword arguments.
3. Implement `view_template` in which you make calls to Phlex' API.

### Simple Component

For example, suppose you want a re-usable button component whose HTML would look like so:

```html
<button class="button button__small button__red">
  Delete Files
</button>
```

Your button can be large (the default) or small, and could be gray (default), green, or red.  Your button could also have an optional `formaction` attribute. Let's also suppose the label could be a string or embedded HTML.

Your constructor would need to accept the size, color, label, and formaction.

You can create a scaffold via `bin/scaffold`:

```
> bin/scaffold component Button
```

You'll first implement the initializer, like so:

```ruby
# app/src/front_end/components/button.rb
class Button < AppComponent
  def initialize(
    size: :large,
    color: :gray,
    formaction: nil,
    label: :use_block
  )
    @size       = size
    @color      = color
    @formaction = formaction
    @label      = label
  end
end
```

This initializer is rather simplistic. You may want to validate the values here to prevent the construction of an invalid component.

Now, implement `view_template`.  This method will receive a block if one is given when the component is used. We'll see an example in a minute.

```ruby
# app/src/front_end/components/button.rb
class Button < AppComponent

  # ...

  def view_template
    attributes = {
      class: [
        "button",
        "button__#{@size}",
        "button__#@{color}",
      ],
      formaction: @formaction,
    }

    button(**attributes) do
      if @label == :use_block
        yield
      else
        @label
      end
    end
  end
end
```

If you've never used Phlex before, it's refreshingly straightforward:

* There's a method for each  HTML element.
* The method's parameters produce attributes in the HTML that is generated.
* If a parameter's value is an array (like `class:`), the values are joined with strings to form the atttribute's value in HTML.
* If the element can have inner content, whatever happens inside a yielded block becomes that inner content.

To use this component, we can call `render` in either the `view_template` of another component or the `page_template` of a [page](/pages):

```ruby
def view_template
  form do
    render Button.new(label: "Submit")
    render Button.new(label: "Nevermind", size: :small, color: :red)
    render Button.new(color: :green) do
      img(src: "/images/ok.png", alt: "OK icon")
    end
  end
end
```

Note that the block passed to `render` is the block available when `yield` is called inside `view_template`.

There are two special types of components beyond what we have just seen.  *Global* Components and *Page private* components.

### Global Components

As we saw above, creating a component is just like creating any Ruby class: you call `.new` on it.  If you create a component that uses request-level data, such as the flash or session, it would mean that any page or component that used *that* component would need to accept the flash or session as a parameter to its initializer, even if it it was otherwise not needed.

In those cases, `global_component` can be used to leverage [keyword injection](/keyword-injection) to have Brut create the component.  That way, its initializer's parameters don't need to be passed into the page or component using the global component.

Suppose we had a component to display the flash:

```ruby
class FlashMessage < AppComponent

  def initialize(flash:)
    @flash = flash
  end

  def view_template
    if @flash.notice?
      div(role: "status") { @flash.notice }
    elsif @flash.alert?
      div(role: "alert") { @flash.alert }
    end
  end
end
```

To use it without having to instantiate it, call `global_component` with the component's class:

```ruby
class HomePage < AppPage
  def page_template
    header do
      global_component(FlashMessage) # note: render not required
    end
  end
end
```

> [!IMPORTANT]
> Brut currently requires an all-or-nothing approach to global components. Either 
> the component can be injected with all its initializer parameters or it must
> be created explicitly by the page or component. You cannot have a component
> receive request-level keyword injection for some parameters with the page
> providing the rest.

Components can also be scoped to a page.

### Page Private Components

Often, components are helpful to simplifying a page's template or managing re-use within a page, but such a component isn't designed for use outside that page.  For example, if the page renders a table, but the logic for each row is complex, you may want that in a separate component, even though it would be useless outside the page.

Brut provides a way to create a *page private* component that exists as an inner class of a page.  It's not truly private, since it's still a Ruby class anyone can use, but it's form and source location communicate intent.

Suppose our `HomePage` has a list of widgets on it, but we want each widget's HTML managed by a separate component:

```ruby
class HomePage < AppPage
  def page_template
    header do
    h1 { "Check out these Widgets!" }
    end
    main do
      ul do
        DB::Widget.all.each do |widget|
          render(HomePage::WidgetListItem.new(widget:))
        end
      end
    end
  end
end
```

`HomePage::WidgetListItem` can be created like so:

```
bin/scaffold component --page=HomePage WidgetListItem
```

This will create `app/src/front_end/pages/home_page/widget_list_item.rb`, which you can then implement like a normal component:

```ruby
# app/src/front_end/pages/home_page/widget_list_item.rb
class HomePage::WidgetListItem < AppComponent
  def initialize(widget:)
    @widget = widget
  end

  def view_template
    li do
      h2 { @widget.name }
      p { @widget.description }
    end
  end
end
```

The only special thing about a page private component is that it can access the page's I18n translations. As we'll discussion in [I18n](/i18n), The `t` method will try to locate translations based on the page on which `t` is called.  A page private component will also trigger this behavior, but a normal component will not.

For example, the following code will look for `pages.HomePage.status.«status»` when generated the `<h3>`:

```ruby {10}
# app/src/front_end/pages/home_page/widget_list_item.rb
class HomePage::WidgetListItem < AppComponent
  def initialize(widget:)
    @widget = widget
  end

  def view_template
    li do
      h2 { @widget.name }
      h3 { t([ :status, @widget.status ]) }
      p { @widget.description }
    end
  end
end
```

## Testing

Test widgets exactly as you would [pages](/pages#testing). The only difference is that components always render HTML and have no `before_generate` concept.

## Recommended Practices

The [recommended practices for pages](/pages#recommended-practices) all apply to components, too.

Beyond that, components are intended to be lightweight, so use them liberally.  Any page or component that has complex markup can be extracted to another component and more easily unit-tested.


## Technical Notes

> [!IMPORTANT]
> Technical Notes are for deeper understanding and debugging. While we will try to keep them up-to-date with changes to Brut's
> internals, the source code is always more correct.

_Last Updated May 5, 2025_

As mentioned, components are Phlex components, but have various helpers mixed-into them.  Components are currently tightly coupled to Phlex and there is no plan to allow alternate implementations of view logic that isn't supported by Phlex.
