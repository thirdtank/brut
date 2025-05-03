# Renders a date or timestamp accessibly, using the `<time>` element. Likely you will use this via the {Brut::FrontEnd::Component#time_tag} method. This will account for the current request's time zone. See {Clock}.
class Brut::FrontEnd::Components::TimeTag < Brut::FrontEnd::Component
  include Brut::I18n::ForHTML
  # Creates the component
  # @param timestamp [Time] the timestamp you wish to render. Mutually exclusive with `date`.
  # @param date [Date] the date you wish to render. Mutually exclusive with `timestamp`.
  # @param format [Symbol] the I18n format key fragment to use to locate the strftime format for formatting the timestamp.  This is appended to `"time.formats."` to form the full string. If `skip_year_if_same` is true *and* the year of this timestamp is this year, `"_no_year"` is further appended.  For example, if this value is `:full` and `skip_year_if_same` is false, the I18n key used will be `"time.formats.full"`.  If `skip_year_if_same` is true, the key would be `"time.formats.full_no_year"` only if this year is the year of the timestamp. Otherwise `"time.formats.full"` would be used.
  # @param skip_year_if_same [true|false] if true, and this year is the same year as the timestamp, `"_no_year"` is appened to the value of `format` to form the I18n key to use.  This is applied before `skip_dow_if_not_this_week`'s suffix is.
  # @param skip_dow_if_not_this_week [true|false] if true, and the date/timestamp is within 7 days of now, appends `"no_dow"` to the format string. If this matches a configured format, it's assumed that would be just like `format` but without the day of the week.  This is applied after `skip_year_if_same`'s suffix is.
  # @param attribute_format [Symbol] the I18n format key fragment to use to locate the strftime format for formatting *the `datetime` attribute* of the HTML element that this component renders. Generally, you want to leave this as the default of `:iso_8601`, however if you need to change it, you can.  This value is appeneded to `"time.formats."` to form the complete key. `skip_year_if_same` is not used for this value.
  # @param only_contains_class [Hash] exists because `class` is a reserved word
  # @option only_contains_class [String] :class the value to use for the `class` attribute.
  # @yield No parameters given. This is expected to return markup to appear inside the `<form>` element. If provided, this component
  # will still render the `datetime` attribute, but not the inside.  This is useful if you have a customized date or time display that
  # you would like to be accessible.  If omitted, the tag's contents will be the formated date or timestamp.
  def initialize(
    timestamp: nil,
    date: nil,
    format: :full,
    skip_year_if_same: true,
    skip_dow_if_not_this_week: true,
    attribute_format: :iso_8601,
    clock: :from_request_context,
    **only_contains_class
  )
    require_exactly_one!(timestamp:,date:)

    @date_only = timestamp.nil?
    @timestamp = timestamp || date
    @clock     = if clock == :from_request_context
                   Brut::FrontEnd::RequestContext.current[:clock]
                 else
                   clock
                 end

    formats = [ format ]
    use_no_year = skip_year_if_same && @timestamp.year == Time.now.year
    use_no_dow  = if skip_dow_if_not_this_week
                    $seven_days_ago = (Date.today - 7).to_time
                    $timestamp      = @timestamp.to_time
                    $timestamp < $seven_days_ago
                  else
                    false
                  end
    if use_no_year
      formats.unshift("#{format}_no_year")
    end

    if use_no_dow
      if use_no_year
        formats.unshift("#{format}_no_year_no_dow")
      else
        formats.unshift("#{format}_no_dow")
      end
    end

    assumed_key_base = if @date_only
                         "date.formats"
                       else
                         "time.formats"
                       end

    format_keys = formats.map { |f| "#{assumed_key_base}.#{f}" }

    found_format,_value = formats.zip( ::I18n.t(format_keys) ).detect { |(_key,value)|
      value !~ /^Translation missing/
    }

    if found_format.nil?
      raise ArgumentError,"format #{format} is not a known time format (checked #{format_keys})"
    end

    @format           = found_format.to_sym
    @attribute_format = attribute_format.to_sym
    @class_attribute  = only_contains_class[:class] || ""
  end

  def view_template
    adjusted_value = if @date_only
                       @timestamp
                     else
                       @clock.in_time_zone(@timestamp)
                     end

    datetime_attribute = ::I18n.l(adjusted_value,format: @attribute_format)

    time(class: @class_attribute, datetime: datetime_attribute) do
      if block_given?
        yield
      else
        ::I18n.l(adjusted_value,format: @format)
      end
    end
  end

private

  def require_exactly_one!(timestamp:,date:)
    if timestamp.nil? && date.nil?
      raise ArgumentError,"one of timestamp: or date: are required"
    elsif !timestamp.nil? && !date.nil?
      raise ArgumentError,"only one of timestamp: or date: may be given"
    end
  end


end
