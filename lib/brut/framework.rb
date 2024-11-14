module Brut
  module Framework
    autoload(:App,"brut/framework/app")
    autoload(:Config,"brut/framework/config")
    autoload(:Container,"brut/framework/container")
    autoload(:MCP,"brut/framework/mcp")
    autoload(:ProjectEnvironment,"brut/framework/project_environment")
    autoload(:Error,"brut/framework/errors")
    autoload(:Errors,"brut/framework/errors")
    autoload(:FussyTypeEnforcement,"brut/framework/fussy_type_enforcement")
  end
end
require_relative "framework/mcp"
