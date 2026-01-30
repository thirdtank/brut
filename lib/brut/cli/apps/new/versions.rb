require "pathname"
require "json"
require_relative "version"

class Brut::CLI::Apps::New::Versions
  def initialize
    @brut_version = Brut::VERSION
  end

  def brut_version_specifier     = "~> #{@brut_version}"
  def brut_css_version_specifier = "~#{@brut_version}"
  def brut_js_version_specifier  = "~#{@brut_version}"
end
