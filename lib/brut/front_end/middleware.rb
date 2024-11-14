module Brut::FrontEnd
  class Middleware
  end
  module Middlewares
    autoload(:ReloadApp,"brut/front_end/middlewares/reload_app")
  end
end
