module Brut::CLI::Apps::New
  module Segments
    autoload :BareBones, "brut/cli/apps/new/segments/bare_bones"
    autoload :Demo, "brut/cli/apps/new/segments/demo"
    autoload :Sidekiq, "brut/cli/apps/new/segments/sidekiq"
    autoload :Heroku, "brut/cli/apps/new/segments/heroku"
  end
end
