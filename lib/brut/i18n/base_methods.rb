# Interface for translations.  This is prefered over using Ruby's I18n directly.
# This is intended to be mixed-in to any class that requires this, so that you can more
# expediently access the `t` method.
module Brut::I18n::BaseMethods

  # Access a translation and insert interpolated elemens as needed. This will use the provided key to determine
  # the actual full key to the translation, as described below.  The value returned is not HTML escaped,
  # assuming that you have not placed HTML injections in your own translation files.  Interpolated
  # values *are* HTML escaped, so external input is safe to provide.
  #
  # This method also may take a block, and the results of the block are inserted into the `%{block}`
  # interpolation value in the i18n string, if it's present.
  #
  # Any missing interpolation will result in an exception, *except* for the value `field`. When
  # a string has `%{field}` in it, but `field:` is omitted in this call, the value for 
  # `"general.cv.this_field"` is used. This value, in English, is "this field", so a call
  # to `t("email.required")` would generate `"This field is required"`, while a call
  # to `t("email.required", field: "E-mail address")` would generate `"E-mail address is required"`.
  #
  # @param [String,Symbol,Array<String>,Array<Symbol>] key used to create one or more keys to be translated.
  #        This value's behavior is designed to a balance predictabilitiy in what actual key is chosen
  #        but without needless repetition on a page.  If this value is provided, and is an array, the values
  #        are joined with "." to form a key.  If the value is not an array, that value is used directly.
  #        Given this key, two values are checked for a translation: the key itself and 
  #        the key inside "general.".  If this value is *not* provided, it is expected
  #        taht the `**rest` hash includes page: or component:.  See that parameter and the example.
  #
  # @param [Hash] rest values to use for interpolation of the key's translation. If `key` is omitted,
  #               this hash should have a value for either `page:` or `component:` (not both).  If
  #               `page:` is present, it is assumed that the class that has included this module
  #               is a `Brut::FrontEnd::Page` or is a page component.  It's `page_name` will be used to create
  #               a key based on the value of `page:`: `pages.«page_name».«page: value»`.
  #               if `component:` is included, the behavior is the same but for `component` instead of `page`.
  # @option interpolated_values [Numeric] count Special interpolation to control pluralization.
  #
  # @raise [I18n::MissingTranslation] if no translation is found
  # @raise [I18n::MissingInterpolationArgument] if interpolation arguments are missing, or if the key
  #                                             has pluralizations and no count: was given
  #
  # @example Simplest usage
  #   # in your translations file
  #   en: {
  #     general: {
  #       hello: "Hi!"
  #     },
  #     formalized: {
  #       hello: "Greetings!"
  #     }
  #   }
  #   # in your code
  #   t(:hello) # => Hi!
  #   t("formalized.hello") # => Greetings!
  #
  # @example Using an array for the key
  #   # in your translations file
  #   en: {
  #     general: {
  #       actions: {
  #         edit: "Make an edit"
  #       }
  #     },
  #   }
  #   # in your code
  #   t([:actions, :edit]) # => Make an edit
  #
  # @example Using page:
  #   # in your translations file
  #   en: {
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
  #   t(page: :new_widget) # => Create new Widget
  #   # in your code for WidgetsPage
  #   t(page: :new_widget) # => Create New
  #
  # @example Using page: with an array
  #   # in your translations file
  #   en: {
  #     pages: {
  #       WidgetsPage: {
  #         new_widget: "Create New"
  #         captions: {
  #           new: "New Widgets"
  #         }
  #       },
  #     },
  #   }
  #   # in your code for HomePage
  #   t(page: [ :captions, :new ]) # => New Widgets
  def t(key=:look_in_rest,**rest)
    if key == :look_in_rest

      page      = rest.delete(:page)
      component = rest.delete(:component)

      if !page.nil? && !component.nil?
        raise ArgumentError, "You may only specify page or component, not both"
      end

      if page
        key = ["pages.#{self.page_name}.#{Array(page).join('.')}"]
      elsif component
        key = ["components.#{self.component_name}.#{Array(component).join('.')}"]
      else
        raise ArgumentError, "If you omit an explicit key, you must specify page or component"
      end
    else
      key = Array(key).join('.')
      key = [key,"general.#{key}"]
    end
    if block_given?
      if rest[:block]
        raise ArgumentError,"t was given a block and a block: param. You can't do both "
      end
      rest[:block] = html_safe(yield.to_s.strip)
    end
    html_safe(t_direct(key,**rest))
  rescue I18n::MissingInterpolationArgument => ex
    if ex.key.to_s == "block"
      raise ArgumentError,"One of the keys #{key.join(", ")} contained a %{block} interpolation value: '#{ex.string}'. This means you must use t_html *and* yield a block to it"
    else
      raise
    end
  end

  def l(date_like, format: :default)
    ::I18n::l(date_like,format: format)
  end

  def this_field_value
    @__this_field_value ||= ::I18n.t("general.cv.this_field", raise: true)
  end

  # Directly access translations without trying to be smart about deriving the key.  This is useful
  # if you have the exact keys you want.
  #
  # @param [Array<String>,Array<Symbol>] keys list of keys representing what is to be translated. The
  #                                           first key found will be used. If no key in the list is found
  #                                           will raise a I18n::MissingTranslation
  # @param [Hash] interpolated_values value to use for interpolation of the key's translation
  # @option interpolated_values [Numeric] count Special interpolation to control pluralization.
  #
  # @raise [I18n::MissingTranslation] if no translation is found
  # @raise [I18n::MissingInterpolationArgument] if interpolation arguments are missing, or if the key
  #                                             has pluralizations and no count: was given
  def t_direct(keys,interpolated_values={})
    keys = Array(keys).map(&:to_sym)
    default_interpolated_values = {
      field: this_field_value,
    }
    escaped_interpolated_values = interpolated_values.map { |key,value|
      if value.kind_of?(String)
        [ key, Brut::FrontEnd::Template.escape_html(value) ]
      else
        [ key, value ]
      end
    }.to_h
    result = ::I18n.t(keys.first, default: keys[1..-1],raise: true, **default_interpolated_values.merge(escaped_interpolated_values))
    if result.kind_of?(Hash)
      raise I18n::MissingInterpolationArgument.new(:count,interpolated_values,keys.join(","))
    end
    result
  end

end
