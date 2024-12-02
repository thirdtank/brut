module Brut::FrontEnd
  class Middleware
  end
  module Middlewares
    autoload(:Favicon,"brut/front_end/middlewares/favicon")
    autoload(:ReloadApp,"brut/front_end/middlewares/reload_app")
    autoload(:AnnotateBrutOwnedPaths,"brut/front_end/middlewares/annotate_brut_owned_paths")
  end
end
