require "spec_helper"

RSpec.describe TriggerExceptionHandler do
  describe "#handle!" do
    context "key is correct" do
      context "http status given" do
        it "returns that status" do
          handler = described_class.new(status: 401, key: "test-trigger-exception")
          result = handler.handle!
          expect(result).to have_returned_http_status(401)
        end
      end
      context "no http status given" do
        context "message provided" do
          it "raises with that message" do
            handler = described_class.new(message: "test message", key: "test-trigger-exception")
            expect {
              handler.handle!
            }.to raise_error("test message")
          end
        end
        context "no message provided" do
          it "raises with a default message" do
            handler = described_class.new(key: "test-trigger-exception")
            expect {
              handler.handle!
            }.to raise_error("no message provided")
          end
        end
      end
    end
    context "key is incorrect" do
      it "returns 404" do
        handler = described_class.new(status: 401, message: "test message")
        result = handler.handle!
        expect(result).to have_returned_http_status(404)
      end
    end
  end
end

