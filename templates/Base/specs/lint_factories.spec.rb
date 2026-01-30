require "spec_helper"
RSpec.describe "factories" do
  it "should be possible to create them all" do
    FactoryBot.lint traits: true
  end
end

