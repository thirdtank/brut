# I18n holds all the code useful for translating and localizing information. It's based on Ruby's I18n.
module Brut::I18n
  autoload(:BaseMethods, "brut/i18n/base_methods")
  autoload(:ForBackEnd, "brut/i18n/for_back_end")
  autoload(:ForCLI, "brut/i18n/for_cli")
  autoload(:ForHTML, "brut/i18n/for_html")
  autoload(:HTTPAcceptLanguage, "brut/i18n/http_accept_language")
end
