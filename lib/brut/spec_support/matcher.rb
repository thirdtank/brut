# Holds custom matchers useful in various tests.
module Brut::SpecSupport::Matchers
end
require_relative "matchers/be_a_bug"
require_relative "matchers/be_page_for"
require_relative "matchers/be_routing_for"
require_relative "matchers/have_constraint_violation"
require_relative "matchers/have_html_attribute"
require_relative "matchers/have_i18n_string"
require_relative "matchers/have_redirected_to"
require_relative "matchers/have_generated"
require_relative "matchers/have_returned_http_status"
require_relative "matchers/have_returned_rack_response"
require_relative "matchers/have_link_to"
