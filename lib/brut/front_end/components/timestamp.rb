require "rexml"
# Renders a timestamp accessibly, using the `<time>` element. Likely you will use this via the {Brut::FrontEnd::Component::Helpers#timestamp} method. This will account for the current request's time zone. See {Clock}.
class Brut::FrontEnd::Components::Timestamp < Brut::FrontEnd::Component
  include Brut::I18n::ForHTML
  # Creates the component
  # @param timestamp [Time] the timestamp you wish to render.
  # @param format [Symbol] the I18n format key fragment to use to locate the strftime format for formatting the timestamp.  This is appended to `"time.formats."` to form the full string. If `skip_year_if_same` is true *and* the year of this timestamp is this year, `"_no_year"` is further appended.  For example, if this value is `:full` and `skip_year_if_same` is false, the I18n key used will be `"time.formats.full"`.  If `skip_year_if_same` is true, the key would be `"time.formats.full_no_year"` only if this year is the year of the timestamp. Otherwise `"time.formats.full"` would be used.
  # @param skip_year_if_same [true|false] if true, and this year is the same year as the timestamp, `"_no_year"` is appened to the value of `format` to form the I18n key to use.
  # @param attribute_format [Symbol] the I18n format key fragment to use to locate the strftime format for formatting *the `datetime` attribute* of the HTML element that this component renders. Generally, you want to leave this as the default of `:iso_8601`, however if you need to change it, you can.  This value is appeneded to `"time.formats."` to form the complete key. `skip_year_if_same` is not used for this value.
  # @param only_contains_class [Hash] exists because `class` is a reserved word
  # @option only_contains_class [String] :class the value to use for the `class` attribute.
  def initialize(timestamp:, format: :full, skip_year_if_same: true, attribute_format: :iso_8601, **only_contains_class)
    @timestamp = timestamp
    formats = [ format ]
    if @timestamp.year == Time.now.year && skip_year_if_same
      formats.unshift("#{format}_no_year")
    end
    format_keys = formats.map { |f| "#{assumed_key_base}.#{f}" }
    found_format,_value = formats.zip(::I18n.t(format_keys)).detect { |(key,value)|
      value !~ /^Translation missing/
    }
    if found_format.nil?
      raise ArgumentError,"format #{format} is not a known time format (checked #{format_keys})"
    end
    @format = found_format.to_sym

    @attribute_format = attribute_format.to_sym
    @class_attribute = only_contains_class[:class] || ""
  end

  def render(clock:)
    timestamp_in_time_zone = adjust_for_timezone(@timestamp,clock:)
    html_tag(:time, class: @class_attribute, datetime: ::I18n.l(timestamp_in_time_zone,format: @attribute_format)) do
      ::I18n.l(timestamp_in_time_zone,format: @format)
    end
  end

private

  def assumed_key_base = "time.formats"

  def adjust_for_timezone(timestamp,clock:)
    clock.in_time_zone(timestamp)
  end


end
