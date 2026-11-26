# Set max_connections for Sequel based on Sidekiq's env var
ENV["SEQUEL_MAX_CONNECTIONS"] ||= ENV.fetch("SIDEKIQ_CONCURRENCY", "5")

require_relative "bootstrap"
bootstrap = Bootstrap.new.bootstrap!
