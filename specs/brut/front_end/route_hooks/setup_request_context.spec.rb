require "spec_helper"
require "rack/mock"
require "rack-protection"

RSpec.describe Brut::FrontEnd::RouteHooks::SetupRequestContext do
  before do
    instrumentation = double(record_exception: nil)
    allow(Brut).to receive(:container).and_return(
      double(instrumentation:, flash_class: Brut::FrontEnd::Flash)
    )
  end

  after do
    Thread.current.thread_variable_set(:request_context, nil)
  end

  it "sets up the current RequestContext from the session and request" do
    rack_session = {}
    session      = Brut::FrontEnd::Session.new(rack_session:)
    flash        = Brut::FrontEnd::Flash.new(messages: { notice: "example.notice" })
    session.flash = flash
    env = Rack::MockRequest.env_for(
      "https://example.com:8443/widgets?x=1",
      method: "POST",
      input: "the body",
      "rack.session" => rack_session,
    )
    request = Rack::Request.new(env)

    result = described_class.new.before(session:, request:, env:)
    context = Brut::FrontEnd::RequestContext.current

    expect(result).to                eq(true)
    expect(context[:env]).to         eq(env)
    expect(context[:session]).to     eq(session)
    expect(context[:flash].to_h).to  eq(flash.to_h)
    expect(context[:xhr]).to         eq(false)
    expect(context[:body]).to        eq(env["rack.input"])
    expect(context[:host].to_s).to   eq("https://example.com:8443")
  end

  it "records whether the request is an XHR" do
    rack_session = {}
    session      = Brut::FrontEnd::Session.new(rack_session:)
    env = Rack::MockRequest.env_for(
      "/widgets",
      "rack.session" => rack_session,
      "HTTP_X_REQUESTED_WITH" => "XMLHttpRequest",
    )

    described_class.new.before(session:, request: Rack::Request.new(env), env:)

    expect(Brut::FrontEnd::RequestContext.current[:xhr]).to eq(true)
  end
end
