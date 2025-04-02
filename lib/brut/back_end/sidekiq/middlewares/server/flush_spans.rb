# Designed to flush all OTel spans after each job is processed. You likely only
# want this to be configured in development so you can see the results of individual
# job executions.  Do not enable in production.
#
# When using, you want this to be inserted before OTel's sidekiq middleware:
#
#    config.server_middleware do |chain|
#      chain.insert_before OpenTelemetry::Instrumentation::Sidekiq::Middlewares::Server::TracerMiddleware,
#                          Brut::BackEnd::Sidekiq::Middlewares::Server::FlushSpans
#    end
class Brut::BackEnd::Sidekiq::Middlewares::Server::FlushSpans
  def call(worker, job, queue)
    yield
  ensure
    OpenTelemetry.tracer_provider.force_flush
  end
end
