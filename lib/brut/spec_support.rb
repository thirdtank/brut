module Brut
  # Spec Support holds various matchers and helpers useful when writing tests with RSpec.
  # Note that this module and it's contents aren't loaded by default when you `require "brut"`.
  # Your app's `spec_helper.rb` should require these properly.
  module SpecSupport
  end
end
require_relative "spec_support/matcher"
require_relative "spec_support/component_support"
require_relative "spec_support/handler_support"
require_relative "spec_support/general_support"
require_relative "factory_bot"
# Convention here is different. We don't want to autoload
# a lot of stuff, since RSpec pollutes the Object namespace.
# Instead, we'll require that these files are required explicitly
