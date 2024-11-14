require "rexml"
class Brut::FrontEnd::Components::Timestamp < Brut::FrontEnd::Component
  include Brut::I18n::ForHTML
  def initialize(timestamp:, format: :full, skip_year_if_same: true, attribute_format: :iso_8601, **only_contains_class)
    @timestamp = timestamp
    formats = [ format ]
    if @timestamp.year == Time.now.year && skip_year_if_same
      formats.unshift("#{format}_no_year")
    end
    format_keys = formats.map { |f| "time.formats.#{f}" }
    found_format = formats.zip(::I18n.t(format_keys)).detect { |(key,value)|
      value !~ /^Translation missing/
    }.first
    if found_format.nil?
      raise ArgumentError,"format #{format} is not a known time format"
    end
    @format = found_format.to_sym

    if ::I18n.t("time.formats.#{attribute_format}") =~ /^Translation missing/
      raise ArgumentError,"attribute_format #{attribute_format} is not a known time format"
    end
    @attribute_format = attribute_format.to_sym
    @class_attribute = only_contains_class[:class] || ""
  end


  def render(clock:)
    timestamp_in_time_zone = clock.in_time_zone(@timestamp)
    html_tag(:time, class: @class_attribute, datetime: ::I18n.l(timestamp_in_time_zone,format: @attribute_format)) do
      ::I18n.l(timestamp_in_time_zone,format: @format)
    end
  end
end
