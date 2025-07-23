require "spec_helper"

RSpec.describe HomePage do
  it "should show the H1" do
    # Page specs should evaluate the generated HTML, so
    # the generate_and_parse help will accept an instaniated 
    # page (or components), generate its HTML, then use Nokogiri
    # to parse it, return the result.
    result = generate_and_parse(described_class.new)

    # e! is provided by Brut::SpecSupport::EnhancedNode which
    # delegates everything to the underlying Nokogiri::XML::Node
    # while adding a few methods.  e! requires that exactly
    # one element match the given CSS selector, then returns it.
    #
    # Thus, this expectation will fail if:
    # * there is no <h1> (and the error message would indcate this)
    # * there is is more than one <h1> (and the error message would indcate this)
    # * the only <h1>'s text is not exactly "Welcome to Brut"
    expect(result.e!("h1").text).to eq("Welcome to Brut")
  end
end
