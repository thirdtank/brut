# Interface for translations, preferred over Ruby's I18n classes. Note that this is a
# base module and not intended to be directly used in your classes.  Include one of
# the other modules in this namespace:
#
# * {Brut::I18n::ForHTML} for components or pages, or anything use Phlex
# * {Brut::I18n::ForCLI} for CLI apps
# * {Brut::I18n::ForBackEnd} for back-end classes that aren't generating HTML
#
# This module assumes the existence of a three-method protocol that's used for HTML escaping in an
# HTML-generating web context:
#
# * `capture` accepts the block yieled to {#t} and returns whatever it generates.  This needs to exist
#   because Phlex's API renders to an internal buffer by default.  This module needs to allow Phlex
#   API methods to render to a different buffer.
# * `safe` accepts a string and returns a string that is presumed to be HTML safe.
# * `html_escape` accepts a string and returns a string that is HTML escaped.
#
# This module does not implement these methods and assumes that either the class using this module will
# implement them or that a submodule being used does.  All submodules provided by Brut provide implementations,
# so this information is only relevant if you are using this module directly.
module Brut::I18n::BaseMethods

  # Access a translation and insert interpolated elemens as needed. This will use the provided key to determine
  # the actual full key to the translation, as described below. See {Brut::I18n::ForHTML#t} for details
  # on how this works in the context of a {Brut::FrontEnd::Component} or {Brut::FrontEnd::Page}.
  #
  # Any missing interpolation will result in an exception, *except* for the value `field`. When
  # a string has `%{field}` in it, but `field:` is omitted in this call, the value for 
  # `"cv.this_field"` is used. This value, in English, is "this field", so a call
  # to `t("email.required")` would generate `"This field is required"`, while a call
  # to `t("email.required", field: "E-mail address")` would generate `"E-mail address is required"`.
  #
  # @param [String,Symbol,Array<String>,Array<Symbol>] key used to create one or more keys to be translated.
  #        This value's behavior balances predictabilitiy with what key is used and some flexibilty
  #        to allow page– or component–specific translations when needed, and fallbacks when not.
  #
  #        When an array if given, the values are turned into strings and joined with a "." to
  #        form a full key.
  #
  #        Depending on what class this module is mixed into, additional keys will be tried:
  #
  #        * If this is a page, `pages.«page_name».` will be prepended and tried before the key passed in.
  #          If the `pages.«page_name»` version is not found, the exact key passed in is checked.
  #        * If this is a page private component, `pages.«page_name».` will be prepended and tried before
  #          the key passed in. The value for `«page_name»` is determined by the outer class that this
  #          component is a part of.
  #        * If this is a component (include if it is a page private component),
  #          `components.«component_name».` will be prepended and tried before the key passed in.
  #          If the `components.«component_name»` version is not found, the exact key passed in is checked.
  #
  #        The priority of the keys are as follows:
  #
  #        1. Component key is checked (unless this is a page)
  #        2. Page key is checked (unless this is a non-page private component)
  #        3. The literal key passed-in is checked
  #
  #        If no value is found for any key an exception is raised.
  #
  # @param [Hash] interpolated_values values to use for interpolation of the key's translation. Note that if
  #        `:block` is part of this has, you may not pass a block to this method.  Note also
  #        that `:count` can be used if the key is expected to be pluralized.  This value
  #        is required for keys that are designed for pluralization. See examples below.
  # @option interpolated_values [Numeric] count Special interpolation to control pluralization.
  # @option interpolated_values [String] block Value to use for `%{block}`. If this is used, a block may not be
  #                             yielded.
  # @yield If a block is passed, it is used for the value of `%{block}`. No parameters are yielded to the block.
  # @yieldreturn [String] The value to use for the `%{block}` interpolation value.  There is some nuance to
  #                       how this works.  The value returned is given to `capture`, and *that* value
  #                       is given to `safe`.  Outside of an HTML-rendering context, these methods
  #                       simply pass through the contents of the block.  In an HTML-rendering
  #                       context, however, these methods are assumed to be from
  #                       [`Phlex::HTML`](https://phlex.fun).  `capture` will create a new Phlex
  #                       context and capture any HTML built inside the block.  That HTML is assumed
  #                       to be safe, thus `safe` is called to communicate this to Phlex.
  #
  # @raise [I18n::MissingTranslation] if no translation is found
  # @raise [I18n::MissingInterpolationArgument] if interpolation arguments are missing, or if the key
  #                                             has pluralizations and no count: was given
  #
  # @example Simplest usage
  #   # in your translations file
  #   en: {
  #     hello: "Hi!"
  #   }
  #   # in your code
  #   t(:hello) # => Hi!
  #
  # @example Using an array for the key
  #   # in your translations file
  #   en: {
  #     actions: {
  #       edit: "Make an edit"
  #     }
  #   }
  #   # in your code
  #   t([:actions, :edit]) # => Make an edit
  #
  # @example Using page:
  #   # in your translations file
  #   en: {
  #     new_widget: "Make a New Widget",
  #     pages: {
  #       HomePage: {
  #         new_widget: "Create new Widget"
  #       },
  #       WidgetsPage: {
  #         new_widget: "Create New"
  #       },
  #     },
  #   }
  #   # in your code for HomePage
  #   t(:new_widget) # => Create new Widget
  #   # in your code for WidgetsPage
  #   t(:new_widget) # => Create New
  #   # in your code for SomeOtherPage
  #   t(:new_widget) # => Make a New Widget
  #
  # @example Using in a component
  #   # in your translations file
  #   en: {
  #     status: {
  #       ready: "Available",
  #       stalled: "Stalled",
  #       completed: "Done",
  #     },
  #     components: {
  #       TagComponent: {
  #         status: {
  #           ready: "Ready",
  #           stalled: "Waiting",
  #         }
  #       },
  #     },
  #   }
  #   # in your code for TagComponent
  #   t(page: [ :status, :ready ]) # => Ready
  #   t(page: [ :status, :completed ]) # => Done
  #   # in your code for StatusComponent
  #   t(page: [ :status, :ready ]) # => Available
  #   t(page: [ :status, :completed ]) # => Done
  #
  # @example Using in a page-private component
  #   # in your translations file
  #   en: {
  #     status: {
  #       ready: "Available",
  #       stalled: "Stalled",
  #       completed: "Done",
  #     },
  #     pages: {
  #       WidgetsPage: {
  #         new_widget: "Create New",
  #         nevermind: "Don't Create One",
  #       },
  #     }
  #     components: {
  #       "WidgetsPage::WidgetComponent": {
  #         new_widget: "Make New Widget",
  #       },
  #     },
  #   }
  #   # in your code for WidgetsPage::WidgetComponent
  #   t(page: :new_widget) # => Make New Widget
  #   t(page: :nevermind) # => Don't Create One
  #
  # @example Using a block in a page or component
  #   # in your translations file
  #   en: {
  #     greeting: "Hello there %{name}, you may %{block}",
  #   }
  #   # Inside a component where
  #   # Brut::I18n::ForHTML has been included
  #   def view_template
  #     h1 do
  #       raw(t(:greeting), name: user.name) do
  #         a(href: "https://support.example.com") do
  #           "contact support"
  #         end
  #       end
  #     end
  #   end
  #   # This will produce this HTML, assuming user.name is "Pat":
  #   <h1>
  #     Hell there Pat, you may
  #     <a href="https://support.example.com">
  #       contact support
  #     </a>
  #   </h1>
  def t(key,**interpolated_values,&block)
    keys_to_check = []
    key = Array(key).join('.')
    is_page_private_component = self.kind_of?(Brut::FrontEnd::Component) &&
                                self.page_private?
    is_page                   = self.kind_of?(Brut::FrontEnd::Page)
    is_component              = self.kind_of?(Brut::FrontEnd::Component) && !is_page

    if is_component
      keys_to_check << "components.#{self.component_name}.#{key}"
    end
    if is_page
      keys_to_check << "pages.#{self.page_name}.#{key}"
    elsif is_page_private_component
      keys_to_check << "pages.#{self.containing_page_name}.#{key}"
    end
    keys_to_check << key

    if !block.nil?
      if interpolated_values[:block]
        raise ArgumentError,"t was given a block and a block: param. You can't do both "
      end
      block_contents = safe(capture(&block))
      interpolated_values[:block] = block_contents
    end
    t_direct(keys_to_check,**interpolated_values, key_given: key)
  rescue I18n::MissingInterpolationArgument => ex
    if ex.key.to_s == "block"
      raise ArgumentError,"One of the keys #{key.join(", ")} contained a %{block} interpolation value: '#{ex.string}'. This means you must yield a block to `t`"
    else
      raise
    end
  end

  def l(date_like, format: :default)
    ::I18n::l(date_like,format: format)
  end

  def this_field_value
    @__this_field_value ||= ::I18n.t("cv.this_field", raise: true)
  end

  # Directly access translations without trying to be smart about deriving the key.  This is useful
  # if you have the exact keys you want.
  #
  # @param [Array<String>,Array<Symbol>] keys list of keys representing what is to be translated. The
  #                                           first key found will be used. If no key in the list is found
  #                                           will raise a I18n::MissingTranslation. 
  # @param [Hash] interpolated_values value to use for interpolation of the key's translation
  # @option interpolated_values [Numeric] count Special interpolation to control pluralization.
  # @option interpolated_values [String|Symbol] key_given If included, this is not used for interpolation, but
  #                                             will be used in error messages to represent the key
  #                                             given to `t`.
  #
  # @raise [I18n::MissingTranslation] if no translation is found
  # @raise [I18n::MissingInterpolationArgument] if interpolation arguments are missing, or if the key
  #                                             has pluralizations and no count: was given
  def t_direct(keys,interpolated_values={})
    keys = Array(keys).map(&:to_sym)
    key_given = interpolated_values.delete(:key_given)
    default_interpolated_values = {
      field: this_field_value,
    }
    escaped_interpolated_values = interpolated_values.map { |key,value|
      if value.kind_of?(String)
        [ key, html_escape(value) ]
      else
        [ key, value ]
      end
    }.to_h
    result = ::I18n.t(keys.first, default: keys[1..-1],raise: true, **default_interpolated_values.merge(escaped_interpolated_values))
    if result.kind_of?(Hash)
      incorrect_pluralization = result.keys.none? { |key| key == :one }
      if incorrect_pluralization
        key_message = if key_given
                        "Key '#{key_given}'"
                      else
                        "One of the keys"
                      end
        raise Brut::Framework::Errors::Bug,
          "#{key_message} resulted in a Hash that doesn't appear to be created for pluralizations. This means that you may have given a key expecting it to map to a translation but it is actually a namespace for other keys.  Please adjust your translations file to avoid this situation. Keys checked:\n#{keys.join(", ")}\nSub keys found:\n#{result.keys.join(', ')}"
      else
        raise I18n::MissingInterpolationArgument.new(:count,interpolated_values,keys.join(","))
      end
    end
    result
  end

end
