require "pathname"
require "yaml"
# Not here:
#  - prevent use of postfix conditonals entirely
module Brut
  IM_NOT_CALLING_THEM_COPS = {
    "Gemspec/AddRuntimeDependency" => true,
    "Lint/AmbiguousAssignment" => true,
    "Lint/AmbiguousOperator" => true,
    "Lint/AmbiguousOperatorPrecedence" => true,
    "Lint/AmbiguousRange" => true,
    "Lint/AmbiguousRegexpLiteral" => true,
    "Lint/DuplicateCaseCondition" => true,
    "Lint/DuplicateElsifCondition" => true,
    "Lint/Loop" => true,
    "Lint/RedundantSplatExpansion" => true,
    "Lint/RedundantStringCoercion" => true,
    "Lint/RedundantTypeConversion" => true,
    "Lint/ToJSON" => true,
    "Style/ColonMethodDefinition" => true,
    "Style/DefWithParentheses" => true,
    "Style/InvertibleUnlessCondition" => true,
    "Style/KeywordArgumentsMerging" => true,
    "Style/MethodDefParentheses" => true,
    "Style/MissingRespondToMissing" => true,
    "Style/MultilineTernaryOperator" => true,
    "Style/NegatedUnless" => true,
    "Style/NestedTernaryOperator" => true,
    "Style/PreferredHashMethods" => true,
    "Style/UnlessElse" => true,
    "Style/UnlessLogicalOperators" => true,
    "Layout/DotPosition" => {
      "EnforcedStyle" =>  "trailing",
    },
    "Lint/AssignmentInCondition" => {
      "AllowSafeAssignment" =>  "false",
    },
    "Style/ClassMethodsDefinitions" => {
      "EnforcedStyle" =>  "def_self",
    },
    "Style/CollectionMethods" => {
      "PreferredMethods" => {
        "find" => "detect",
        "collect" => "map",
        "find_all" => "select",
        "member?" => "include?",
      },
    },
    "Style/EndlessMethod" => {
      "EnforcedStyle" =>  "allow_single_line",
    },
    "Style/For" => {
      "EnforcedStyle" =>  "each",
    },
    "Style/YodaCondition" => {
      "EnforcedStyle" =>  "forbid_for_all_comparison_operators",
    },
    "Style/DisableSyntax" => {
      "DisableSyntax" => [
        "unless",
        "and_or_not",
        "until",
      ],
    },
    "Style/TrailingCommaInArrayLiteral" => {
      "EnforcedStyleForMultiline" => "consistent_comma",
    },
    "Style/TrailingCommaInHashLiteral" => {
      "EnforcedStyleForMultiline" => "consistent_comma",
    },
    # Documented, but nonexistent
    #"Style/ItBlockParameter" => {
    #  "EnforcedStyle" => "allow_single_line",
    #},
  }
  PREAMBLE = {
    "inherit_mode" => {
      "merge" => [ "Exclude" ],
    },
    "plugins" => [
      "rubocop-disable_syntax",
    ],
    "AllCops" => {
      "DisabledByDefault" => true,
      "TargetRubyVersion" => RUBY_VERSION.split(".")[0..1].join("."),
      "SuggestExtensions" => false,
      "Exclude" => [
        "local-gems/**/*",
        "**/local-gems/**/*",
        "node_modules/**/*",
        "**/node_modules/**/*",
      ],
    },
  }
  class RubocopConfig
    def create_ridiculous_yaml
      if !ARGV[0]
        raise "You must supply the file where the config will be written"
      end
      filename = Pathname(ARGV[0])
      my_big_yaml_hash_of_doom = {}.merge(PREAMBLE)
      IM_NOT_CALLING_THEM_COPS.each do |not_a_cop, config|
        body = case config
               when Hash
                 config
               when Array
                 config
               when true
                 {}
               else
                 raise "#{config.class}/#{config} is not handled by this contraption"
               end
        body["Enabled"] = true
        my_big_yaml_hash_of_doom[not_a_cop] = body
      end
      File.open(filename,"w") do |file|
        file.puts "# This file is generated! DO NOT EDIT (not that you'd want to - it's YAML!)"
        file.puts "# The configuration is canonically stored in lib/brut/rubocop_config.rb"
        file.puts my_big_yaml_hash_of_doom.to_yaml
      end
    end
  end
end
