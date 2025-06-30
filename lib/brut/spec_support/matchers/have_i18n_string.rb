# Component/Page
RSpec::Matchers.define :have_i18n_string do |key,**args|
  include Brut::I18n::ForBackEnd

  match do |nokogiri_node|

    text        = nokogiri_node.text.strip
    i18n_string = t(key,**args).to_s

    text == i18n_string
  end

  failure_message do |nokogiri_node|
    text = nokogiri_node.text.strip
    begin
      "Expected '#{text}' to be '#{t(key,**args)}'\n#{nokogiri_node.to_html}\n"
    rescue => ex
      "I18n key '#{key}' could not be found: #{ex.message}"
    end
  end

  failure_message_when_negated do |nokogiri_node|
    "Did not expect node's text to be '#{t(key,**args)}'\n#{nokogiri_node.to_html}\n"
  end
end

# Used in component or page specs to check if a Nokogiri node's 
# text contains a specific i18n string, without you having
# to use `t` to look it up.
#
# @example
#   result = generate_and_parse(page)
#   expect(result.e!("h3")).to have_i18n_string(:greeting)
#
# @example I18n string with parameters
#   result = generate_and_parse(page)
#   expect(result.e!("h3")).to have_i18n_string(:user_greeting, email: account.email)
class Brut::SpecSupport::Matchers::HaveI18nString
end
