# Renders a date accessibly, using the `<time>` element. Likely you will use this via the {Brut::FrontEnd::Component::Helpers#date} method.
class Brut::FrontEnd::Components::Date < Brut::FrontEnd::Components::Timestamp
  # Creates the component
  # @param date [Date] the date you want to render
  # @param format [Symbol] the I18n format key fragment to use to locate the strftime format for formatting the date.  This is appended to `"date.formats."` to form the full string. If `skip_year_if_same` is true *and* the year of this date is this year, `"_no_year"` is further appended.  For example, if this value is `:full` and `skip_year_if_same` is false, the I18n key used will be `"date.formats.full"`.  If `skip_year_if_same` is true, the key would be `"date.formats.full_no_year"` only if this year is the year of the date. Otherwise `"date.formats.full"` would be used.
  # @param skip_year_if_same [true|false] if true, and this year is the same year as the date, `"_no_year"` is appened to the value of `format` to form the I18n key to use.
  # @param attribute_format [Symbol] the I18n format key fragment to use to locate the strftime format for formatting *the `datetime` attribute* of the HTML element that this component renders. Generally, you want to leave this as the default of `:iso_8601`, however if you need to change it, you can.  This value is appeneded to `"date.formats."` to form the complete key. `skip_year_if_same` is not used for this value.
  # @param only_contains_class [Hash] exists because `class` is a reserved word
  # @option only_contains_class [String] :class the value to use for the `class` attribute.
  def initialize(date:, format: :full, skip_year_if_same: true, attribute_format: :iso_8601, **only_contains_class)
    super(timestamp: date,format:,skip_year_if_same:,attribute_format:,**only_contains_class)
  end

private

  def adjust_for_timezone(timestamp,clock:) = timestamp
  def assumed_key_base = "date.formats"
end
