module Brut::FrontEnd
  # Base class of middlewares you can use in your app. This is currently a marker interface and provides no features
  class Middleware
  end
  # Holds middlewares that are included with Brut and set up with all Brut apps by default
  module Middlewares
    autoload(:Favicon,"brut/front_end/middlewares/favicon")
    autoload(:ReloadApp,"brut/front_end/middlewares/reload_app")
    autoload(:AnnotateBrutOwnedPaths,"brut/front_end/middlewares/annotate_brut_owned_paths")
  end
end
