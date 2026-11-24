require "spec_helper"
require "rack/mock"
require "sinatra"
require "nokogiri"
require "json"

RSpec.describe Brut::SinatraHelpers do
  before do
    # Instrumentation is out of scope for these tests, but Page#handle!,
    # Component#around_template, and Form all call into it.
    span = double(add_prefixed_attributes: nil, add_event: nil)
    instrumentation = double
    allow(instrumentation).to receive(:span) { |_name, &block| block.call(span) }
    allow(instrumentation).to receive(:add_prefixed_attributes)
    allow(instrumentation).to receive(:add_event)
    allow(instrumentation).to receive(:add_attributes)

    allow(Brut).to receive(:container).and_return(
      double(
        public_root_dir: "/tmp",
        permitted_hosts: [],
        routing: Brut::FrontEnd::Routing.new,
        instrumentation: instrumentation,
        webhook_url_path_prefix: "/webhooks",
        project_env: Brut::Framework::ProjectEnvironment.new("test")
      )
    )

    rack_env = {
      "rack.session" => {},
    }
    request_context = Brut::FrontEnd::RequestContext.new(
      env: rack_env,
      session: Brut::FrontEnd::Session.new(rack_session: rack_env["rack.session"]),
      flash: Brut::FrontEnd::Flash.new,
      xhr: false,
      body:"",
      host: URI("http://example.com")
    )
    Thread.current.thread_variable_set(:request_context,request_context)

    stub_const("PageProbeLayout", Class.new(Brut::FrontEnd::Layout) do
      def view_template = main(id: "page-probe-layout") { yield }
    end)
  end

  after do
    Thread.current.thread_variable_set(:request_context, nil)
  end

  let(:sinatra_app) {
    Class.new(Sinatra::Base) do
      include Brut::SinatraHelpers
    end
  }

  describe "page" do
    it "redirects when before_generate returns a URI" do
      stub_const("PageProbeRedirectPage", Class.new(Brut::FrontEnd::Page) do
        def before_generate = URI("https://example.com/redirected")

        def page_template = h1 { "PAGE RENDERED" }
      end)

      sinatra_app.page "/page-probe-redirect"
      response = Rack::MockRequest.new(sinatra_app).get("/page-probe-redirect")

      expect(response.status).to eq(302)
      expect(response.headers["location"]).to eq("https://example.com/redirected")
    end

    it "returns the HTTP status when before_generate returns an HttpStatus" do
      stub_const("PageProbeHttpStatusPage", Class.new(Brut::FrontEnd::Page) do
        def before_generate = Brut::FrontEnd::HttpStatus.new(404)

        def page_template = h1 { "PAGE RENDERED" }
      end)

      sinatra_app.page "/page-probe-http-status"
      response = Rack::MockRequest.new(sinatra_app).get("/page-probe-http-status")

      expect(response.status).to eq(404)
    end

    it "renders the page and returns its HTML for a GET" do
      stub_const("PageProbePage", Class.new(Brut::FrontEnd::Page) do
        def layout = "page_probe"

        def page_template = h1 { "page content" }
      end)

      sinatra_app.page "/page-probe"

      response = Rack::MockRequest.new(sinatra_app).get("/page-probe")

      expect(response.status).to eq(200)
      document = Nokogiri::HTML5(response.body)
      expect(document.at_css("#page-probe-layout h1")&.text).to eq("page content")
      expect(Rack::MockRequest.new(sinatra_app).post("/page-probe").status).to eq(404)
    end

    it "gives the page the request's parameters via the request context" do
      stub_const("PageProbeParamsPage", Class.new(Brut::FrontEnd::Page) do
        def initialize(greeting:)
          @greeting = greeting
        end

        def layout = "page_probe"

        def page_template = h1 { @greeting }
      end)
      allow(Brut::FrontEnd::RequestContext.current).to receive(:as_constructor_args) do |_klass, request_params:, **|
        { greeting: request_params["greeting"] }
      end

      sinatra_app.page "/page-probe-params"

      response = Rack::MockRequest.new(sinatra_app).get("/page-probe-params?greeting=hi")

      document = Nokogiri::HTML5(response.body)
      expect(document.at_css("#page-probe-layout h1")&.text).to eq("hi")
    end

    # before_generate documents that it may return a GenericResponse, but the
    # page route has no branch for it.
    it "sends a GenericResponse returned by before_generate" do
      stub_const("PageProbeGenericResponsePage", Class.new(Brut::FrontEnd::Page) do
        def layout = "page_probe"

        def before_generate
          Brut::FrontEnd::GenericResponse.new(
            http_status: 202,
            headers: { "Content-Type" => "text/plain" },
            response_body: ["accepted"],
          )
        end

        def page_template = h1 { "PAGE RENDERED" }
      end)

      sinatra_app.page "/page-probe-generic-response"

      response = Rack::MockRequest.new(sinatra_app).get("/page-probe-generic-response")

      expect(response.status).to eq(202)
      expect(response.headers["content-type"]).to eq("text/plain")
      expect(response.body).to eq("accepted")
    end
  end

  describe "form" do
    it "instantiates the form with the request's parameters and passes it to the handler" do
      stub_const("WidgetsForm", Class.new(Brut::FrontEnd::Form) do
        input :name
      end)
      stub_const("WidgetsHandler", Class.new(Brut::FrontEnd::Handler) do
        def initialize(form:)
          @form = form
        end

        def handle!
          Brut::FrontEnd::GenericResponse.new(
            http_status: 200,
            headers: { "Content-Type" => "application/json" },
            response_body: [@form.to_h.to_json],
          )
        end
      end)

      sinatra_app.form "/widgets"

      response = Rack::MockRequest.new(sinatra_app).post("/widgets", params: { name: "Pat" })

      expect(response.status).to eq(200)
      expect(JSON.parse(response.body)).to eq("name" => "Pat")
    end

    it "redirects when the handler returns a URI" do
      stub_const("WidgetsForm", Class.new(Brut::FrontEnd::Form))
      stub_const("WidgetsHandler", Class.new(Brut::FrontEnd::Handler) do
        def initialize(form:)
          @form = form
        end

        def handle! = URI("https://example.com/next")
      end)

      sinatra_app.form "/widgets"

      response = Rack::MockRequest.new(sinatra_app).post("/widgets")

      expect(response.status).to eq(303)
      expect(response.headers["location"]).to eq("https://example.com/next")
    end

    it "renders the component when the handler returns one" do
      stub_const("WidgetsForm", Class.new(Brut::FrontEnd::Form))
      stub_const("WidgetsComponent", Class.new(Brut::FrontEnd::Component) do
        def view_template = h1 { "widget" }
      end)
      stub_const("WidgetsHandler", Class.new(Brut::FrontEnd::Handler) do
        def initialize(form:)
          @form = form
        end

        def handle! = WidgetsComponent.new
      end)

      sinatra_app.form "/widgets"

      response = Rack::MockRequest.new(sinatra_app).post("/widgets")

      expect(response.status).to eq(200)
      expect(response.body).to include("<h1>widget</h1>")
    end

    it "renders the component and uses the status when the handler returns [Component, HttpStatus]" do
      stub_const("WidgetsForm", Class.new(Brut::FrontEnd::Form))
      stub_const("WidgetsComponent", Class.new(Brut::FrontEnd::Component) do
        def view_template = h1 { "widget" }
      end)
      stub_const("WidgetsHandler", Class.new(Brut::FrontEnd::Handler) do
        def initialize(form:)
          @form = form
        end

        def handle! = [WidgetsComponent.new, Brut::FrontEnd::HttpStatus.new(422)]
      end)

      sinatra_app.form "/widgets"

      response = Rack::MockRequest.new(sinatra_app).post("/widgets")

      expect(response.status).to eq(422)
      expect(response.body).to include("<h1>widget</h1>")
    end

    it "returns only the status when the handler returns an HttpStatus" do
      stub_const("WidgetsForm", Class.new(Brut::FrontEnd::Form))
      stub_const("WidgetsHandler", Class.new(Brut::FrontEnd::Handler) do
        def initialize(form:)
          @form = form
        end

        def handle! = Brut::FrontEnd::HttpStatus.new(404)
      end)

      sinatra_app.form "/widgets"

      response = Rack::MockRequest.new(sinatra_app).post("/widgets")

      expect(response.status).to eq(404)
      expect(response.body).to eq("")
    end

    it "sends a download when the handler returns a Download" do
      stub_const("WidgetsForm", Class.new(Brut::FrontEnd::Form))
      stub_const("WidgetsHandler", Class.new(Brut::FrontEnd::Handler) do
        def initialize(form:)
          @form = form
        end

        def handle!
          Brut::FrontEnd::Download.new(
            filename: "widget.txt",
            data: "widget data",
            content_type: "text/plain",
          )
        end
      end)

      sinatra_app.form "/widgets"

      response = Rack::MockRequest.new(sinatra_app).post("/widgets")

      expect(response.status).to eq(200)
      expect(response.body).to eq("widget data")
      expect(response.headers["content-disposition"]).to eq('attachment; filename="widget.txt"')
      expect(response.headers["content-type"]).to eq("text/plain")
    end

    it "sends the response when the handler returns a GenericResponse" do
      stub_const("WidgetsForm", Class.new(Brut::FrontEnd::Form))
      stub_const("WidgetsHandler", Class.new(Brut::FrontEnd::Handler) do
        def initialize(form:)
          @form = form
        end

        def handle!
          Brut::FrontEnd::GenericResponse.new(
            http_status: 201,
            headers: { "Content-Type" => "text/plain" },
            response_body: ["created"],
          )
        end
      end)

      sinatra_app.form "/widgets"

      response = Rack::MockRequest.new(sinatra_app).post("/widgets")

      expect(response.status).to eq(201)
      expect(response.headers["content-type"]).to eq("text/plain")
      expect(response.body).to eq("created")
    end

    it "raises when the handler returns an unsupported value" do
      stub_const("WidgetsForm", Class.new(Brut::FrontEnd::Form))
      stub_const("WidgetsHandler", Class.new(Brut::FrontEnd::Handler) do
        def initialize(form:)
          @form = form
        end

        def handle! = Object.new
      end)

      sinatra_app.form "/widgets"
      sinatra_app.set :raise_errors, true

      expect {
        Rack::MockRequest.new(sinatra_app).post("/widgets")
      }.to raise_error(NoMatchingPatternError, /cannot be used to understand/)
    end

    it "runs the page's before_generate hook when the handler returns a Page" do
      stub_const("WidgetsForm", Class.new(Brut::FrontEnd::Form))
      stub_const("WidgetsRedirectLayout", Class.new(Brut::FrontEnd::Layout) do
        def view_template = div { yield }
      end)
      stub_const("WidgetsRedirectPage", Class.new(Brut::FrontEnd::Page) do
        def layout = "widgets_redirect"

        def before_generate = URI("https://example.com/redirected")

        def page_template = h1 { "PAGE RENDERED" }
      end)
      stub_const("WidgetsHandler", Class.new(Brut::FrontEnd::Handler) do
        def initialize(form:)
          @form = form
        end

        def handle! = WidgetsRedirectPage.new
      end)

      sinatra_app.form "/widgets"

      response = Rack::MockRequest.new(sinatra_app).post("/widgets")

      expect(response.status).to eq(303)
      expect(response.headers["location"]).to eq("https://example.com/redirected")
      expect(response.body).not_to include("PAGE RENDERED")
    end
  end

  describe "action" do
    it "registers a POST route for the handler" do
      stub_const("WidgetsActionHandler", Class.new(Brut::FrontEnd::Handler))

      sinatra_app.action "/widgets-action"

      route = Brut.container.routing.for(path: "/widgets-action", method: :post)
      expect(route.http_method.to_sym).to eq(:post)
      expect(route.handler_class).to eq(WidgetsActionHandler)
      expect(Brut.container.routing.for(path: "/widgets-action", method: :get)).to be_nil
    end
  end

  describe "path" do
    it "registers the route with the given HTTP method" do
      stub_const("WidgetsStatusHandler", Class.new(Brut::FrontEnd::Handler))

      sinatra_app.path "/widgets-status", method: :get

      route = Brut.container.routing.for(path: "/widgets-status", method: :get)
      expect(route.http_method.to_sym).to eq(:get)
      expect(route.handler_class).to eq(WidgetsStatusHandler)
      expect(Brut.container.routing.for(path: "/widgets-status", method: :post)).to be_nil
    end
  end

  describe "webhook" do
    it "registers the route under the webhook path prefix" do
      stub_const("Webhooks", Module.new)
      Webhooks.const_set(:StripeHandler, Class.new(Brut::FrontEnd::Handler))

      sinatra_app.webhook "stripe"

      route = Brut.container.routing.for(path: "/webhooks/stripe", method: :post)
      expect(route.http_method.to_sym).to eq(:post)
      expect(route.handler_class).to eq(Webhooks::StripeHandler)
      expect(Brut.container.routing.for(path: "/stripe", method: :post)).to be_nil
    end
  end
end
