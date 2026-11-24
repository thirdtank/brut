require "spec_helper"
require "nokogiri"

RSpec.describe Brut::FrontEnd::Page do
  before do
    span = double(add_prefixed_attributes: nil, add_event: nil)
    instrumentation = double
    allow(instrumentation).to receive(:span) { |_name, &block| block.call(span) }
    allow(instrumentation).to receive(:add_prefixed_attributes)
    allow(Brut).to receive(:container).and_return(double(instrumentation: instrumentation))

    stub_const("PageSpecLayout", Class.new(Brut::FrontEnd::Layout) {
      def view_template = div(id: "page-spec-layout") { yield }
    })
  end

  def parse(html) = Nokogiri::HTML5(html)

  describe "#handle!" do
    context "when before_generate returns a URI" do
      it "returns the URI instead of generating the page" do
        page_class = stub_const("PageSpecPage", Class.new(Brut::FrontEnd::Page) {

          def layout          = "page_spec"
          def before_generate = URI("https://example.com/redirected")
          def page_template   = h1 { "PAGE RENDERED" }

        })

        result = page_class.new.handle!

        expect(result).to eq(URI("https://example.com/redirected"))
      end
    end

    context "when before_generate returns an HttpStatus" do
      it "returns the HttpStatus instead of generating the page" do
        page_class = stub_const("PageSpecPage", Class.new(Brut::FrontEnd::Page) {

          def layout          = "page_spec"
          def before_generate = Brut::FrontEnd::HttpStatus.new(404)
          def page_template   = h1 { "PAGE RENDERED" }

        })

        result = page_class.new.handle!

        expect(result).to be_a(Brut::FrontEnd::HttpStatus)
        expect(result.to_i).to eq(404)
      end
    end

    context "when before_generate returns a GenericResponse" do
      it "returns the Rack response instead of generating the page" do
        page_class = stub_const("PageSpecPage", Class.new(Brut::FrontEnd::Page) {
          def layout = "page_spec"

          def before_generate
            Brut::FrontEnd::GenericResponse.new(
              http_status: 202,
              headers: { "Content-Type" => "text/plain" },
              response_body: ["accepted"],
            )
          end

          def page_template = h1 { "PAGE RENDERED" }
        })

        result = page_class.new.handle!

        expect(result).to have_returned_rack_response(
          http_status: 202,
          headers: { "Content-Type" => "text/plain" },
          body: ["accepted"],
        )
      end
    end

    context "when before_generate returns nil" do
      it "generates the page inside its layout" do
        page_class = stub_const("PageSpecPage", Class.new(Brut::FrontEnd::Page) {

          def layout          = "page_spec"
          def before_generate = nil
          def page_template   = h1(id: "page-content") { "page content" }

        })

        result = page_class.new.handle!

        expect(result).to be_a(String)
        document = parse(result)
        expect(document.at_css("#page-spec-layout h1#page-content")&.text).to eq("page content")
      end
    end

    context "when before_generate returns anything else" do
      it "generates the page inside its layout" do
        page_class = stub_const("PageSpecPage", Class.new(Brut::FrontEnd::Page) {

          def layout          = "page_spec"
          def before_generate = false
          def page_template   = h1(id: "page-content") { "rendered anyway" }

        })

        result = page_class.new.handle!

        expect(result).to be_a(String)
        document = parse(result)
        expect(document.at_css("#page-spec-layout h1#page-content")&.text).to eq("rendered anyway")
      end
    end
  end

  describe "layout rendering" do
    it "renders page_template inside the layout named by #layout" do
      page_class = stub_const("PageSpecPage", Class.new(Brut::FrontEnd::Page) {

        def layout        = "page_spec"
        def page_template = h1(id: "page-content") { "page content" }

      })

      document = parse(page_class.new.handle!)

      expect(document.at_css("#page-spec-layout h1#page-content")&.text).to eq("page content")
    end

    it "uses the default layout when #layout is not overridden" do
      stub_const("DefaultLayout", Class.new(Brut::FrontEnd::Layout) {
        def view_template = main(id: "default-layout") { yield }
      })
      page_class = stub_const("PageSpecPage", Class.new(Brut::FrontEnd::Page) {
        def page_template = h1(id: "page-content") { "default layout content" }
      })

      document = parse(page_class.new.handle!)

      expect(document.at_css("#default-layout h1#page-content")&.text).to eq("default layout content")
    end

    it "camelizes multi-word layout names to locate the layout class" do
      stub_const("FancyPageLayout", Class.new(Brut::FrontEnd::Layout) {
        def view_template = section(id: "fancy-page-layout") { yield }
      })
      page_class = stub_const("PageSpecPage", Class.new(Brut::FrontEnd::Page) {

        def layout        = "fancy_page"
        def page_template = h1(id: "page-content") { "fancy content" }

      })

      document = parse(page_class.new.handle!)

      expect(document.at_css("#fancy-page-layout h1#page-content")&.text).to eq("fancy content")
    end

    it "allows an instance of page to change its layout hased on state" do
      stub_const("FancyPageLayout", Class.new(Brut::FrontEnd::Layout) {
        def view_template = section(id: "fancy-page-layout") { yield }
      })
      page_class = stub_const("PageSpecPage", Class.new(Brut::FrontEnd::Page) {
        def initialize(fancy:)
          @fancy = fancy
        end

        def layout        = @fancy ? "fancy_page" : "page_spec"
        def page_template = h1(id: "page-content") { "dynamic content" }

      })

      plain_document = parse(page_class.new(fancy: false).handle!)
      fancy_document = parse(page_class.new(fancy: true).handle!)

      expect(plain_document.at_css("#page-spec-layout h1#page-content")&.text).to eq("dynamic content")
      expect(plain_document.at_css("#fancy-page-layout")).to be_nil
      expect(fancy_document.at_css("#fancy-page-layout h1#page-content")&.text).to eq("dynamic content")
      expect(fancy_document.at_css("#page-spec-layout")).to be_nil
    end

    it "makes the page available to the layout" do
      stub_const("PageSpecAwareLayout", Class.new(Brut::FrontEnd::Layout) {
        def view_template = aside(id: "aware-layout", data_page: page.class.name) { yield }
      })
      page_class = stub_const("PageSpecPage", Class.new(Brut::FrontEnd::Page) {

        def layout        = "page_spec_aware"
        def page_template = h1(id: "page-content") { "aware content" }

      })

      document = parse(page_class.new.handle!)

      layout = document.at_css("#aware-layout")
      expect(layout["data-page"]).to eq("PageSpecPage")
      expect(layout.at_css("h1#page-content")&.text).to eq("aware content")
    end
  end
end
