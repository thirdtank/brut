require "spec_helper"
require "nokogiri"

RSpec.describe Brut::FrontEnd::Components::Inputs::CsrfToken do

  before do
    span = double(add_prefixed_attributes: nil)
    instrumentation = double
    allow(instrumentation).to receive(:span) { |_name, &block| block.call(span) }
    allow(Brut).to receive(:container).and_return(double(instrumentation: instrumentation))
  end

  def input_from(html) = Nokogiri::HTML5(html).at_css("input")

  describe "generating HTML" do
    it "generates a hidden input named authenticity_token whose value is the CSRF token" do
      input = input_from(described_class.new(csrf_token: "tok-123").call)

      expect(input["type"]).to  eq("hidden")
      expect(input["name"]).to  eq("authenticity_token")
      expect(input["value"]).to eq("tok-123")
    end
  end
end
