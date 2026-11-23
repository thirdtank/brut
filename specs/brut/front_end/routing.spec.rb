require "spec_helper"
require "zeitwerk"

# Routing locates handler classes by naming convention, so these stubs are
# the minimum needed to register routes without booting an app.
class TestWidgetsHandler; end
class TestWidgetsWithIdHandler; end
class UnregisteredHandler; end
class TestPage; end
class TestFormsHandler; end
class TestFormsForm; end
class TestActionsHandler; end
class TestPathsHandler; end
class TestPostsHandler; end

module Webhooks
  class TestHooksHandler; end
end

RSpec.describe Brut::FrontEnd::Routing do
  let(:routing) do
    described_class.new.tap do |r|
      r.register_path("/test-widgets", method: :get)
      r.register_path("/test-widgets/:id", method: :get)
    end
  end

  describe "#route" do
    it "returns the route registered for a handler class" do
      route = routing.route(TestWidgetsWithIdHandler)

      expect(route.path_template).to eq("/test-widgets/:id")
      expect(route.http_method.to_sym).to eq(:get)
      expect(route.handler_class).to eq(TestWidgetsWithIdHandler)
    end

    it "returns the route registered for a form class" do
      routing = described_class.new
      route = routing.register_form("/test-forms")

      expect(routing.route(TestFormsForm)).to be(route)
    end

    it "raises ArgumentError when no route is registered for the handler class" do
      expect { routing.route(UnregisteredHandler) }.to raise_error(ArgumentError)
    end
  end

  describe "#for" do
    it "returns the route matching the path and method" do
      routing = described_class.new
      get_route  = routing.register_path("/test-paths", method: :get)
      post_route = routing.register_path("/test-posts", method: :post)

      expect(routing.for(path: "/test-paths", method: :get)).to be(get_route)
      expect(routing.for(path: "/test-posts", method: :post)).to be(post_route)
    end

    it "returns nil when the path does not match" do
      routing = described_class.new
      routing.register_path("/test-paths", method: :get)

      expect(routing.for(path: "/other-paths", method: :get).nil?).to eq(true)
    end

    it "returns nil when the method does not match" do
      routing = described_class.new
      routing.register_path("/test-paths", method: :get)

      expect(routing.for(path: "/test-paths", method: :post).nil?).to eq(true)
    end

    it "matches path templates literally, including placeholders" do
      routing = described_class.new
      route = routing.register_path("/test-widgets/:id", method: :get)

      expect(routing.for(path: "/test-widgets/:id", method: :get)).to be(route)
      expect(routing.for(path: "/test-widgets/42", method: :get).nil?).to eq(true)
    end

    it "normalizes the method" do
      routing = described_class.new
      route = routing.register_path("/test-paths", method: :get)

      expect(routing.for(path: "/test-paths", method: "GET")).to be(route)
    end
  end

  describe "#path" do
    it "substitutes path parameters into the path and returns a URI safe for Phlex" do
      uri = routing.path(TestWidgetsWithIdHandler, id: "42")

      expect(uri.to_s).to eq("/test-widgets/42")
      expect(uri.is_a?(URI::Generic)).to eq(true)
      expect(uri.is_a?(Phlex::SGML::SafeObject)).to eq(true)
    end

    it "raises MissingParameter when a path parameter is not provided" do
      expect { routing.path(TestWidgetsWithIdHandler) }.to raise_error(Brut::Framework::Errors::MissingParameter)
    end

    it "puts parameters that are not part of the template into the query string" do
      uri = routing.path(TestWidgetsWithIdHandler, id: "42", page: "2", q: "a b&c")

      expect(uri.path).to eq("/test-widgets/42")
      expect(uri.query).to eq("page=2&q=a+b%26c")
    end

    it "percent-encodes the anchor" do
      uri = routing.path(TestWidgetsWithIdHandler, id: "42", anchor: "a b")

      expect(uri.to_s).to eq("/test-widgets/42#a%20b")
    end

    # The values below are raw values, not pre-encoded. Each must become a
    # single, percent-encoded path segment. Today they are inserted verbatim
    # and then parsed by URI(), so several of these change the URL's shape
    # or make it invalid.
    {
      "a b"      => "/test-widgets/a%20b",
      "foo#bar"  => "/test-widgets/foo%23bar",
      "foo?x=1"  => "/test-widgets/foo%3Fx%3D1",
      "foo&bar"  => "/test-widgets/foo%26bar",
      "100%"     => "/test-widgets/100%25",
      "café"     => "/test-widgets/caf%C3%A9",
    }.each do |value, expected|
      it "percent-encodes path parameter value #{value.inspect} as a single path segment" do
        uri = routing.path(TestWidgetsWithIdHandler, id: value)

        expect(uri.to_s).to eq(expected)
        expect(uri.fragment.nil?).to eq(true)
        expect(uri.query.nil?).to eq(true)
      end
    end

    it "rejects path parameter values containing a slash" do
      expect { routing.path(TestWidgetsWithIdHandler, id: "foo/bar") }.to raise_error(ArgumentError)
    end

    it "rejects dot-segment path parameter values" do
      expect { routing.path(TestWidgetsWithIdHandler, id: ".") }.to raise_error(ArgumentError)
      expect { routing.path(TestWidgetsWithIdHandler, id: "..") }.to raise_error(ArgumentError)
    end

    it "treats non-String path parameter values as their string representation" do
      expect(routing.path(TestWidgetsWithIdHandler, id: 42).to_s).to eq("/test-widgets/42")
      expect(routing.path(TestWidgetsWithIdHandler, id: 4.2).to_s).to eq("/test-widgets/4.2")
      expect(routing.path(TestWidgetsWithIdHandler, id: :widget).to_s).to eq("/test-widgets/widget")
    end

    it "rejects dot-segment path parameter values that are not Strings" do
      expect { routing.path(TestWidgetsWithIdHandler, id: :"..") }.to raise_error(ArgumentError)
    end

    it "returns the route's path, allowing the route's method or :any" do
      expect(routing.path(TestWidgetsHandler, with_method: :get).to_s).to eq("/test-widgets")
      expect(routing.path(TestWidgetsHandler, with_method: :any).to_s).to eq("/test-widgets")
      expect(routing.path(TestWidgetsHandler).to_s).to eq("/test-widgets")
    end

    it "raises ArgumentError when with_method: does not match the route's method" do
      expect { routing.path(TestWidgetsHandler, with_method: :post) }.to raise_error(ArgumentError)
    end

    it "raises ArgumentError when a route with path parameters is used with the wrong method" do
      expect { 
        routing.path(
          TestWidgetsWithIdHandler,
          with_method: :post,
        )
      }.to raise_error(ArgumentError)
    end
  end

  describe "#url" do
    it "returns an absolute URL for the route, using the fallback host" do
      container = Brut::Framework::Container.new
      container.store("fallback_host", URI, "", URI("https://example.com"))
      allow(Brut).to receive(:container).and_return(container)

      expect(routing.url(TestWidgetsWithIdHandler, with_method: :get, id: "42", page: "2").to_s).to eq("https://example.com/test-widgets/42?page=2")
    end
  end

  describe "#register_page" do
    it "registers a GET route for the page and returns it" do
      routing = described_class.new
      route   = routing.register_page("/test")

      expect(route.path_template).to eq("/test")
      expect(route.http_method.to_sym).to eq(:get)
      expect(route.handler_class).to eq(TestPage)
      expect(routing.for(path: "/test", method: :get)).to be(route)
      expect(TestPage.respond_to?(:routing)).to eq(true)
    end

    it "does not register a second route for the same path" do
      routing = described_class.new
      routing.register_page("/test")
      routing.register_page("/test")

      # XXX: Not great bob
      routes = routing.instance_variable_get("@routes").to_a
      expect(routes.length).to eq(1), routes.inspect
    end
  end

  describe "#register_form" do
    it "registers a POST route for the form and returns it" do
      routing = described_class.new
      route   = routing.register_form("/test-forms")

      expect(route.path_template).to eq("/test-forms")
      expect(route.http_method.to_sym).to eq(:post)
      expect(route.handler_class).to eq(TestFormsHandler)
      expect(route.form_class).to eq(TestFormsForm)
      expect(routing.for(path: "/test-forms", method: :post)).to be(route)
      expect(TestFormsHandler.respond_to?(:routing)).to eq(true)
      expect(TestFormsForm.respond_to?(:routing)).to eq(true)
    end

    it "does not register a second route for the same path" do
      routing = described_class.new
      routing.register_form("/test-forms")
      routing.register_form("/test-forms")

      expect(routing.inspect.lines.length).to eq(1)
    end
  end

  describe "#register_handler_only" do
    it "registers a POST route for the handler and returns it" do
      routing = described_class.new
      route   = routing.register_handler_only("/test-actions")

      expect(route.path_template).to eq("/test-actions")
      expect(route.http_method.to_sym).to eq(:post)
      expect(route.handler_class).to eq(TestActionsHandler)
      expect(route.respond_to?(:form_class)).to eq(false)
      expect(routing.for(path: "/test-actions", method: :post)).to be(route)
      expect(TestActionsHandler.respond_to?(:routing)).to eq(true)
    end

    it "does not register a second route for the same path" do
      routing = described_class.new
      routing.register_handler_only("/test-actions")
      routing.register_handler_only("/test-actions")

      expect(routing.inspect.lines.length).to eq(1)
    end
  end

  describe "#register_path" do
    it "registers a route for the given path and method and returns it" do
      routing = described_class.new
      route   = routing.register_path("/test-paths", method: :get)

      expect(route.path_template).to eq("/test-paths")
      expect(route.http_method.to_sym).to eq(:get)
      expect(route.handler_class).to eq(TestPathsHandler)
      expect(routing.for(path: "/test-paths", method: :get)).to be(route)
      expect(TestPathsHandler.respond_to?(:routing)).to eq(true)
    end

    it "does not register a second route for the same path and method" do
      routing = described_class.new
      routing.register_path("/test-paths", method: :get)
      routing.register_path("/test-paths", method: :get)

      expect(routing.inspect.lines.length).to eq(1)
    end
  end

  describe "#register_webhook" do
    it "registers a POST route under the webhook path prefix and returns it" do
      container = Brut::Framework::Container.new
      container.store("webhook_url_path_prefix", String, "", "/webhooks")
      allow(Brut).to receive(:container).and_return(container)
      routing = described_class.new

      route = routing.register_webhook("test-hooks", method: :post)

      expect(route.path_template).to eq("/webhooks/test-hooks")
      expect(route.http_method.to_sym).to eq(:post)
      expect(route.handler_class).to eq(Webhooks::TestHooksHandler)
      expect(routing.for(path: "/webhooks/test-hooks", method: :post)).to be(route)
      expect(Webhooks::TestHooksHandler.respond_to?(:routing)).to eq(true)
    end

    it "does not register a second route for the same path and method" do
      container = Brut::Framework::Container.new
      container.store("webhook_url_path_prefix", String, "", "/webhooks")
      allow(Brut).to receive(:container).and_return(container)
      routing = described_class.new

      routing.register_webhook("test-hooks", method: :post)
      routing.register_webhook("test-hooks", method: :post)

      expect(routing.inspect.lines.length).to eq(1)
    end

    it "raises when the path already starts with the webhook path prefix" do
      container = Brut::Framework::Container.new
      container.store("webhook_url_path_prefix", String, "", "/webhooks")
      allow(Brut).to receive(:container).and_return(container)
      routing = described_class.new

      expect { routing.register_webhook("/webhooks/test-hooks", method: :post) }.to raise_error(ArgumentError)
    end
  end

  describe "#reload" do
    # Zeitwerk replaces app classes with new class objects on reload. #reload
    # must rebuild the routes against those new objects and re-add the
    # `.routing` method that register_* installed on the old ones.
    it "recreates the route and its .routing method on the reloaded handler class" do
      Dir.mktmpdir do |dir|
        File.write(File.join(dir, "reloadable_handler.rb"), "class ReloadableHandler; end\n")

        loader = Zeitwerk::Loader.new
        loader.push_dir(dir)
        loader.enable_reloading
        loader.setup

        begin
          routing = described_class.new
          routing.register_path("/reloadable", method: :get)
          old_class = ReloadableHandler
          expect(old_class.respond_to?(:routing)).to eq(true)

          loader.reload
          new_class = ReloadableHandler
          expect(new_class.equal?(old_class)).to eq(false)
          expect(new_class.respond_to?(:routing)).to eq(false)

          container = Brut::Framework::Container.new
          container.store("routing", Brut::FrontEnd::Routing, "", routing)
          allow(Brut).to receive(:container).and_return(container)

          routing.reload

          expect(new_class.respond_to?(:routing)).to eq(true)
          expect(routing.for(path: "/reloadable", method: :get).handler_class).to be(new_class)
          expect(new_class.routing.to_s).to eq("/reloadable")
        ensure
          loader.unload
        end
      end
    end

    it "recreates the route and its .routing method on a reloaded page class" do
      Dir.mktmpdir do |dir|
        File.write(File.join(dir, "reloadable_page.rb"), "class ReloadablePage; end\n")

        loader = Zeitwerk::Loader.new
        loader.push_dir(dir)
        loader.enable_reloading
        loader.setup

        begin
          routing = described_class.new
          routing.register_page("/reloadable")
          old_class = ReloadablePage
          expect(old_class.respond_to?(:routing)).to eq(true)

          loader.reload
          new_class = ReloadablePage
          expect(new_class.equal?(old_class)).to eq(false)
          expect(new_class.respond_to?(:routing)).to eq(false)

          routing.reload

          expect(new_class.respond_to?(:routing)).to eq(true)
          expect(routing.for(path: "/reloadable", method: :get).handler_class).to be(new_class)
        ensure
          loader.unload
        end
      end
    end

    it "reloads a route whose handler could not be found" do
      container = Brut::Framework::Container.new
      container.store("project_env", Brut::Framework::ProjectEnvironment, "", Brut::Framework::ProjectEnvironment.new("development"))
      allow(Brut).to receive(:container).and_return(container)

      routing = described_class.new
      routing.register_path("/missing-paths", method: :get)
      expect(routing.for(path: "/missing-paths", method: :get).class).to eq(described_class::MissingPath)

      routing.reload

      expect(routing.for(path: "/missing-paths", method: :get).class).to eq(described_class::MissingPath)
    end
  end
end
