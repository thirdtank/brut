# Useful middlewares for Sidekiq jobs
module Brut::BackEnd::Sidekiq::Middlewares
  autoload(:Server, "brut/back_end/sidekiq/middlewares/server")
end
