# Mostly based on Heroku's guidance:
# https://devcenter.heroku.com/articles/deploying-rails-applications-with-the-puma-web-server

# Ensures the logger is setup and availbale as early as possible
require "semantic_logger"

# workers should be set to the # of cores. Heroku
# recommends the following, with 2 as a default if you don't have a good
# reason to change it.
workers Integer(ENV["WEB_CONCURRENCY"] || 2)

# Heroku recommens 5 as a default, with the ability
# to change it as needed.
threads_count = Integer(ENV["PUMA_MAX_THREADS"] || 5)

# This actually sets the min and max # of threads.
# Heroku recommends setting them both to the thread_count
# above.
threads threads_count, threads_count

# Indicate that the app should be loaded before any
# forking or thread creation. Despite the bang,
# this doesn't actually do anything - it just sets configuration
preload_app!

# Support IPv6 by binding to host `::` instead of `0.0.0.0`
port(ENV["PORT"] || 3000, "::")

# Turn off keepalive support for better long tails response time with Router 2.0
# Remove this line when https://github.com/puma/puma/issues/3487 is closed, and the fix is released
if respond_to?(:enable_keep_alives)
  enable_keep_alives(false)
end

# Commenting this out as a) we don't default DefaultRackup
# and b) I don't exactly know what it means or does.
# rackup      DefaultRackup if defined?(DefaultRackup)

# Set the environment based on RACK_ENV
environment ENV["RACK_ENV"]

before_fork do
  # Per http://sequel.jeremyevans.net/rdoc/files/doc/fork_safety_rdoc.html
  # we must disconnect before forking.  Sequel will reconnect as needed.
  Sequel::DATABASES.each(&:disconnect)
end

on_worker_boot do
  # Per https://logger.rocketjob.io/forking.html we want to reopen
  # this to avoid issues
  SemanticLogger.reopen
end

