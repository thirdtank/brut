require "sidekiq"
# Encapsulates all Sidekiq configuraiton beyond what can be done in
# app/config/sidekiq.yml.  You can edit this as needed.
class SidekiqSegment

  def initialize
    Brut.container.store(
      "flush_spans_in_sidekiq?",
      "Boolean",
      "True if sidekiq jobs should flush all OTel spans after the job completes"
    ) do |project_env|
      if ENV["FLUSH_SPANS_IN_SIDEKIQ"] == "true"
        true
      elsif ENV["FLUSH_SPANS_IN_SIDEKIQ"] == "false"
        false
      else
        project_env.development?
      end
    end
  end

  def boot!
    Sidekiq.configure_server do |config|
      config.redis = {
        # Per https://devcenter.heroku.com/articles/connecting-heroku-redis#connecting-in-ruby
        ssl_params: {
          verify_mode: OpenSSL::SSL::VERIFY_NONE,
        },
      }
      config.logger = SemanticLogger["Sidekiq:server"]
      if Brut.container.flush_spans_in_sidekiq?
        SemanticLogger[self.class].info("Sidekiq jobs will flush spans")
        config.server_middleware do |chain|
          if defined? OpenTelemetry::Instrumentation::Sidekiq::Middlewares::Server::TracerMiddleware
            chain.insert_before OpenTelemetry::Instrumentation::Sidekiq::Middlewares::Server::TracerMiddleware,
                                Brut::BackEnd::Sidekiq::Middlewares::Server::FlushSpans
          else
            SemanticLogger["Sidekiq:server"].warn("OpenTelemetry::Instrumentation::Sidekiq::Middlewares::Server::TracerMiddleware not defined")
          end
        end
      else
        SemanticLogger[self.class].info("Sidekiq jobs will not flush spans")
      end
    end

    Sidekiq.configure_client do |config|
      config.redis = {
        # Per https://devcenter.heroku.com/articles/connecting-heroku-redis#connecting-in-ruby
        ssl_params: {
          verify_mode: OpenSSL::SSL::VERIFY_NONE,
        },
      }
      config.logger = SemanticLogger["Sidekiq:client"]
    end
  end
end
