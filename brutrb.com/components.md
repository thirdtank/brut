# Components

Components in Brut are Phlex Components: a class that can hold data and use that to generate HTML.  Components are the primary way you achieve re-use of markup or view logic.

## Overview

`Brut::FrontEnd::Component` inherits from `Phlex::HTML`, which means that to create a component you must do three things:

1. Create a class in `app/src/front_end/components` that inherites from `AppComponent` (which is part of your app and inherits from `Brut::FrontEnd::Component`)
2. Implement an initializer that receives anything your component needs to do its job.  It is recommended (but not required) that your initializer use only keyword arguments.
3. Implement `view_template` in which you make calls to Phlex' API.

### Simple Component


For example, suppose you want a re-usable button that can be gray, green, or red, and have an optional `formaction`.


You can create a component with `bin/scaffold component`:

```
bin/scaffold component button
# => app/src/front_end/components/button_component.rb
# => specs/front_end/components/button_component.spec.rb
```

Component inititalizers are called by you when you use them, so you can define it
how you like.  Brut uses keyword arguments by convention.

```ruby
# app/src/front_end/components/button_component.rb
class ButtonComponent < AppComponent
  def initialize(color: :gray,
                 formaction: nil)
    @color      = color
    @formaction = formaction
  end
end
```

Since it's a Phlex component, implement `view_template` to generate the HTML you
like.  Our `view_template` will `yield` so the button's contents can be controlled
by the caller.  Note that the CSS here is [BrutCSS](/brut-css/index.html), but it
can be anything you are using in your oapp.

```ruby
# app/src/front_end/components/button_component.rb
class ButtonComponent < AppComponent

  # ...

  def view_template
    attributes = {
      class: [
        "tc",               # centered text
        "br-3",             # border radius @ 3rd step of scale
        "bn",               # no border
        "f-3",              # font size @ 3rd step of scale
        "ph-4",             # horizontal padding @ 4th step of scale
        "pv-2",             # vertical padding @ 2nd step of scale
        "bg-#{@color}-800", # background is second lighest of scale
        "#{@color}-300",    # text is third darkest of scale
      ],
      formaction: @formaction
    }

    button(**attributes) do
      yield
    end
  end
end
```

Here are two examples of how you'd use this component and the HTML that would be
generated:

::: code-group

```ruby
render ButtonComponent(color: :green) do
  "Click Here"
end
```

```html
<button class="tc br-3 bn f-3 ph-4 pv-2 bg-green-800 green-300">
  Click Here
<button>
```

:::

::: code-group

```ruby
render ButtonComponent(color: :red, formaction: DeleteWidget.routing) do
  "Delete Widget"
end
```

```html
<button class="tc br-3 bn f-3 ph-4 pv-2 bg-red-800 green-300"
        formaction="/delete_widget">
  Delete Widget
<button>
```
:::

One issue with components is that you must pass them all their initializer arguments
to use them.  This means that if your component needs access to, say, the session,
any page or component that uses your component must also require the session to
be passed in.

Brut provides a partial solution to this called *global components*.

### Global Components

A global component can be created by Brut using [keyword
injection](/keyword-injection). This means that, in our example above, a page that
uses your component does not need to be given the session.  It can have Brut inject
it.

This provides a partial solution to so-called "prop drilling".

In [the features overview](/features), we saw a basic component for rendering a
flash:

```ruby
# components/flash_component.rb
class FlashComponent < AppComponent
  def initialize(flash:)
    if flash.notice?
      @message_key = flash.notice
      @role = :info
    elsif flash.alert?
      @message_key = flash.alert
      @role = :alert
    end
  end

  def any_message? = !@message_key.nil?

  def view_template
    if any_message?
      div(role: @role) do
        t([ :flash, @message_key ])
      end
    end
  end
end
```

Instead of requiring each user of this component to manually inject the flash, we
can call `global_component`, provided by `Brut::FrontEnd::Component::Helpers`, which
is included in all pages and components.

```ruby
def view_template
  header do
    global_component(FlashComponent)
  end
end
```

Components used in layouts will tend to be global components, to avoid creating odd
dependencies between pages.

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

They can be created with `bin/scaffold`:

```
bin/scaffold component --page HomePage Widget
# => app/src/front_end/page/home_page/widget_component.rb
# => specs/front_end/page/home_page/widget_component.spec.rb
```

The class will be an inner class of `HomePage` in this example, `HomePage::WidgetComponent`. You build them and use them like normal:

::: code-group

```ruby [Page]
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

```ruby [Page Private Component]
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

:::

The main difference between a page-private component and a normal component's
behavior is how [I18n](/i18n) strings are resolved.  In short, given this:

```ruby
p do
  t(:hello)
end
```

In a normal component named `WidgetComponent`, the keys searched for translations
would be `"components.WidgetComponent.hello"` and `"hello"` .  For the page-private
component `HomePage::WidgetComponent`, the keys searched would be
`"pages.HomePage.hello"` and `"hello"`.  This means that page private components can
access a page's translations.



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
