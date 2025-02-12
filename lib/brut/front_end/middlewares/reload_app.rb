# Reloads the app without requiring a restart. This should only be used in development.  Every single request will trigger this.
class Brut::FrontEnd::Middlewares::ReloadApp < Brut::FrontEnd::Middleware
  LOCK = Concurrent::ReadWriteLock.new
  def initialize(app)
    @app = app
  end
  def call(env)
    path = env["PATH_INFO"].to_s
    dir = if path[0] == "/"
            path.split(/\//)[1]
          else
            path.split(/\//)[0]
          end
    reload = !["static","js","css","__brut"].include?(dir)
    if reload
      # We can only have one thread reloading stuff at a time, per process.
      # The ReadWriteLock achieves this.
      #
      # Here, if any thread is serving a request, THIS thread will wait here.
      # Once no other thread is serving a request, the write lock is acquired and a reload happens.
      Brut.container.instrumentation.span(self.class.name) do |span|
        LOCK.with_write_lock do
          span.add_event("lock acquired")
          begin
            Brut.container.zeitwerk_loader.reload
            span.add_event("Zeitwerk reloaded")
            Brut.container.routing.reload
            span.add_event("Routing reloaded")
            Brut.container.asset_path_resolver.reload
            span.add_event("Asset Path Resolver reloaded")
            ::I18n.reload!
            span.add_event("I18n reloaded")
          rescue => ex
            SemanticLogger[self.class].warn("Reload failed - your browser may not show you the latest code: #{ex.message}\n#{ex.backtrace}")
          end
        end
      end
      # If another thread has a write lock, we wait here so that the reload can complete before serving
      # the request.  If no thread has a write lock, THIS thread may proceed to serve the request,
      # as will any other thread that gets here.
      LOCK.with_read_lock do
        @app.call(env)
      end
    else
      Brut.container.instrumentation.add_event("Not reloading")
      @app.call(env)
    end
  end
end
