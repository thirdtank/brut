# Useful server middlewares for Sidekiq
module Brut::BackEnd::Sidekiq::Middlewares::Server
  autoload(:FlushSpans, "brut/back_end/sidekiq/middlewares/server/flush_spans")
end
