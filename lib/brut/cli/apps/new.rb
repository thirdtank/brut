require "json"
require "fileutils"

require "brut/cli"

module Brut::CLI::Apps::New

  autoload :AddSegmentOptions  , "brut/cli/apps/new/add_segment_options"
  autoload :AddSegment         , "brut/cli/apps/new/add_segment"
  autoload :App                , "brut/cli/apps/new/app"
  autoload :AppId              , "brut/cli/apps/new/app_id"
  autoload :AppName            , "brut/cli/apps/new/app_name"
  autoload :AppOptions         , "brut/cli/apps/new/app_options"
  autoload :Base               , "brut/cli/apps/new/base"
  autoload :Cli                , "brut/cli/apps/new/cli"
  autoload :ErbBindingDelegate , "brut/cli/apps/new/erb_binding_delegate"
  autoload :InternetIdentifier , "brut/cli/apps/new/internet_identifier"
  autoload :InvalidIdentifier  , "brut/cli/apps/new/invalid_identifier"
  autoload :Ops                , "brut/cli/apps/new/ops"
  autoload :Organization       , "brut/cli/apps/new/organization"
  autoload :Prefix             , "brut/cli/apps/new/prefix"
  autoload :PrefixedIO         , "brut/cli/apps/new/prefixed_io"
  autoload :Segments           , "brut/cli/apps/new/segments"
  autoload :Versions           , "brut/cli/apps/new/versions"

end
