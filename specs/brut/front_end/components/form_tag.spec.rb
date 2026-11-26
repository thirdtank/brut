require "spec_helper"
require "nokogiri"
require "rack-protection"

RSpec.describe Brut::FrontEnd::Components::FormTag do

  let(:rack_env) { "test" }
  let(:request_context) {
    rack_env = {
      "rack.session" => {
        csrf: "csrf-token-value",
      },
    }
    Brut::FrontEnd::RequestContext.new(
      env: rack_env,
      session: Brut::FrontEnd::Session.new(rack_session: rack_env["rack.session"]),
      flash: Brut::FrontEnd::Flash.new,
      xhr: false,
      body:"",
      host: URI("http://example.com")
    )
  }

  before do
    project_env     = Brut::Framework::ProjectEnvironment.new(rack_env)
    routing         = Brut::FrontEnd::Routing.new
    span            = double(add_prefixed_attributes: nil)
    instrumentation = double

    allow(instrumentation).to receive(:span) { |_name, &block| block.call(span) }

    container = Brut::Framework::Container.new
    container.store("instrumentation", Object, "Instrumentation", instrumentation)
    container.store("project_env", Brut::Framework::ProjectEnvironment, "Project environment", project_env)
    container.store("routing", Brut::FrontEnd::Routing, "Routing", routing)
    allow(Brut).to receive(:container).and_return(container)

    Thread.current.thread_variable_set(:request_context, request_context)
  end

  after do
    Thread.current.thread_variable_set(:request_context, nil)
  end

  def form_from(html) = Nokogiri::HTML5(html).at_css("form")

  describe "rendering" do
    it "renders a form with the normalized method, action, and the block's content" do

      stub_const("WidgetsForm", Class.new(Brut::FrontEnd::Form))
      stub_const("WidgetsHandler", Class.new(Brut::FrontEnd::Handler))
      Brut.container.routing.register_form("/widgets")

      form_tag = described_class.new(method: "POST", action: "/widgets") do |inner|
        inner.input(type: "text", name: "name", id: "name")
      end

      form = form_from(form_tag.call)

      expect(form["method"]).to eq("post")
      expect(form["action"]).to eq("/widgets")
      expect(form.at_css("input#name")).not_to eq(nil)
    end
  end

  describe "CSRF token" do
    it "is included as a hidden input for POST forms, with no omission comment" do
      form_tag = described_class.new(method: :post, action: "/widgets")

      html  = form_tag.call
      token = form_from(html).at_css("input[type=hidden][name=authenticity_token]")

      expect(token).not_to eq(nil)
      expect(token["value"]).to eq(request_context[:csrf_token])
      expect(html).not_to include("CSRF Token omitted")
    end

    it "is omitted for GET forms, with no comment outside of development" do
      form_tag = described_class.new(method: :get, action: "/widgets")

      html = form_tag.call

      expect(form_from(html).at_css("input[name=authenticity_token]")).to eq(nil)
      expect(html).not_to include("CSRF Token omitted")
    end

    context "in dev" do
      let("rack_env") { "development" }
      it "renders a development-only comment explaining the omission for GET forms" do
        form_tag = described_class.new(method: :get, action: "/widgets")

        html = form_tag.call

        expect(html).to include("CSRF Token omitted because this form")
        expect(html).to include("this message only appears in development")
      end
    end
  end

  describe "enctype" do
    context "for a POST" do
      it "is multipart/form-data" do
        form_tag = described_class.new(method: :post, action: "/widgets")

        expect(form_from(form_tag.call)["enctype"]).to eq("multipart/form-data")
      end

      it "is omitted if explicitly set as nil" do
        form_tag = described_class.new(method: :post, action: "/widgets", enctype: nil)

        expect(form_from(form_tag.call)["enctype"]).to eq(nil)
      end
    end

    context "for a GET" do
      it "is not set" do
        form_tag = described_class.new(method: :get, action: "/widgets")

        expect(form_from(form_tag.call)["enctype"]).to eq(nil)
      end
      it "is set if explicitly set in the constructor" do
        form_tag = described_class.new(method: :get, action: "/widgets", enctype: "foo")

        expect(form_from(form_tag.call)["enctype"]).to eq("foo")
      end
    end
  end

  describe "for:" do
    it "derives the method and action from the class's route, passing along route_params" do
      form_class = Class.new(Brut::FrontEnd::Form)

      stub_const("WidgetsWithIdForm", form_class)
      stub_const("WidgetsWithIdHandler", Class.new(Brut::FrontEnd::Handler))
      Brut.container.routing.register_form("/widgets/:id")

      form_tag = described_class.new(for: form_class, route_params: { id: "1" })

      form = form_from(form_tag.call)

      expect(form["method"]).to eq("post")
      expect(form["action"]).to eq("/widgets/1")
    end

    it "raises if action: is also given" do
      form_class = Class.new(Brut::FrontEnd::Form)

      expect {
        described_class.new(for: form_class, action: "/widgets")
      }.to raise_error(ArgumentError, /cannot specify both/)
    end

    it "raises if method: is also given" do
      form_class = Class.new(Brut::FrontEnd::Form)

      expect {
        described_class.new(for: form_class, method: :post)
      }.to raise_error(ArgumentError, /cannot specify both/)
    end
  end
end
