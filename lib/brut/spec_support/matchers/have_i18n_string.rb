RSpec::Matchers.define :have_i18n_string do |key,**args|
  include Brut::I18n::ForHTML

  # XXX: Figure out how to not have to do this
  def safe(x) = x
  def capture(&block) = block.()

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

