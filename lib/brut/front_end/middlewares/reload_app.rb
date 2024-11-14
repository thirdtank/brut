class Brut::FrontEnd::Middlewares::ReloadApp < Brut::FrontEnd::Middleware
  LOCK = Concurrent::ReadWriteLock.new
  def initialize(app)
    @app = app
  end
  def call(env)
    Brut.container.instrumentation.instrument(Brut::Instrumentation::Event.new(category: "middleware", subcategory: self.class.name, name: "call")) do
      # We can only have one thread reloading stuff at a time, per process.
      # The ReadWriteLock achieves this.
      #
      # Here, if any thread is serving a request, THIS thread will wait here.
      # Once no other thread is serving a request, the write lock is acquired and a reload happens.
      LOCK.with_write_lock do
        begin
          Brut.container.zeitwerk_loader.reload
          Brut.container.routing.reload
          Brut.container.asset_path_resolver.reload
          ::I18n.reload!
        rescue => ex
          SemanticLogger[self.class].warn("Reload failed - your browser may not show you the latest code: #{ex.message}")
        end
      end
      # If another thread has a write lock, we wait here so that the reload can complete before serving
      # the request.  If no thread has a write lock, THIS thread may proceed to serve the request,
      # as will any other thread that gets here.
      LOCK.with_read_lock do
        @app.call(env)
      end
    end
  end
end
