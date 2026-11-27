require "spec_helper"
require "rack/mock"
require "rack/protection"

RSpec.describe Brut::FrontEnd::Layouts::Default do
  class DefaultLayoutTestPage < Brut::FrontEnd::Page
    def page_template
      h1 { "Widgets" }
    end
  end

  # What a generated app has: a subclass of the Brut-provided layout.
  class DefaultLayout < Brut::FrontEnd::Layouts::Default
    def page_title = "Default Layout Test"
  end

  before do
    span = double(add_prefixed_attributes: nil)
    instrumentation = double(add_attributes: nil, add_prefixed_attributes: nil, record_exception: nil)
    allow(instrumentation).to receive(:span).and_yield(span)

    container = Brut::Framework::Container.new
    container.store("instrumentation", Object, "Instrumentation", instrumentation)
    container.store("project_env", Object, "Project environment", double(production?: false))
    container.store("asset_path_resolver", Object, "Asset path resolver", double(resolve: "/assets/hashed"))
    allow(Brut).to receive(:container).and_return(container)

    @original_available_locales = ::I18n.available_locales.dup
    @original_locale = ::I18n.locale
    ::I18n.available_locales = [:en, :ar]

    env = Rack::MockRequest.env_for("https://example.com/widgets")
    env["rack.session"] = {}
    Brut::FrontEnd::RequestContext.current = Brut::FrontEnd::RequestContext.new(
      env:,
      session: Brut::FrontEnd::Session.new(rack_session: env["rack.session"]),
      flash: Brut::FrontEnd::Flash.new,
      xhr: false,
      body: nil,
      host: URI("https://example.com"),
    )
  end

  after do
    Brut::FrontEnd::RequestContext.clear_current!
    ::I18n.available_locales = @original_available_locales
    ::I18n.locale = @original_locale
  end

  it "sets lang and dir from the current locale for a right-to-left language" do
    ::I18n.locale = :ar

    expect(DefaultLayoutTestPage.new.call).to include('<html lang="ar" dir="rtl">')
  end

  it "sets lang and dir from the current locale for a left-to-right language" do
    ::I18n.locale = :en

    expect(DefaultLayoutTestPage.new.call).to include('<html lang="en" dir="ltr">')
  end

  it "includes the traceparent meta tag" do
    html = DefaultLayoutTestPage.new.call

    expect(html).to include('name="traceparent"')
  end

  it "includes the page identifier meta tag" do
    html = DefaultLayoutTestPage.new.call

    expect(html).to include('<meta name="class" content="DefaultLayoutTestPage">')
  end

  it "uses the subclass's page title" do
    expect(DefaultLayoutTestPage.new.call).to include("<title>Default Layout Test</title>")
  end
end
