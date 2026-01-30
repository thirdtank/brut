module Brut::CLI::Apps::New
  module Ops
    autoload :BaseOp, "brut/cli/apps/new/ops/base_op"
    autoload :Mkdir, "brut/cli/apps/new/ops/mkdir"
    autoload :CopyFile, "brut/cli/apps/new/ops/copy_file"
    autoload :RenderTemplate, "brut/cli/apps/new/ops/render_template"
    autoload :SkipFile, "brut/cli/apps/new/ops/skip_file"
    autoload :InsertRoute, "brut/cli/apps/new/ops/insert_route"
    autoload :InsertCodeInMethod, "brut/cli/apps/new/ops/insert_code_in_method"
    autoload :AppendToFile, "brut/cli/apps/new/ops/append_to_file"
    autoload :InsertIntoFile, "brut/cli/apps/new/ops/insert_into_file"
    autoload :PrismParsingOp, "brut/cli/apps/new/ops/prism_parsing_op"
    autoload :AddI18nMessage, "brut/cli/apps/new/ops/add_i18n_message"
    autoload :AddCSSImport, "brut/cli/apps/new/ops/add_css_import"
    autoload :AddMethod, "brut/cli/apps/new/ops/add_method"
  end
end
