module MKBrut
  module Ops
    autoload :BaseOp, "mkbrut/ops/base_op"
    autoload :Mkdir, "mkbrut/ops/mkdir"
    autoload :CopyFile, "mkbrut/ops/copy_file"
    autoload :RenderTemplate, "mkbrut/ops/render_template"
    autoload :SkipFile, "mkbrut/ops/skip_file"
    autoload :InsertRoute, "mkbrut/ops/insert_route"
    autoload :InsertCodeInMethod, "mkbrut/ops/insert_code_in_method"
    autoload :AppendToFile, "mkbrut/ops/append_to_file"
    autoload :PrismParsingOp, "mkbrut/ops/prism_parsing_op"
    autoload :AddI18nMessage, "mkbrut/ops/add_i18n_message"
    autoload :AddCSSImport, "mkbrut/ops/add_css_import"
    autoload :AddMethod, "mkbrut/ops/add_method"
  end
end
