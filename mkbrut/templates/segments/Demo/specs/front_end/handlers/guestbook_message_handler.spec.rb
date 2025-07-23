require "spec_helper"

RSpec.describe GuestbookMessageHandler do
  describe "#handle!" do
    context "there are client-side constraint violations" do
      it "generates the new guestbook message page" do
        form            = GuestbookMessageForm.new(params: {})
        flash           = empty_flash
        session         = empty_session
        rack_request_ip = Faker::Internet.ip_v4_address

        confidence_check do
          expect(form).to have_constraint_violation(:name,key: :valueMissing)
        end

        handler = described_class.new(
          form:,
          flash:,
          session:,
          rack_request_ip:
        )
        result = nil
        expect {
          result = handler.handle
        }.not_to change { DB::GuestbookMessage.count }

        expect(result).to have_generated(NewGuestbookMessagePage)
        expect(flash.alert).to eq("guestbook_not_saved")
      end
    end
    context "there are server-side constraint violations" do
      it "indicates a server-side error and generates the new guestbook message page" do
        form            = GuestbookMessageForm.new(params: {
          name: "Pat",
          message: "FIRSTPOST!!!!",
        })
        flash           = empty_flash
        session         = empty_session
        rack_request_ip = Faker::Internet.ip_v4_address

        handler = described_class.new(
          form:,
          flash:,
          session:,
          rack_request_ip:
        )
        result = nil
        expect {
          result = handler.handle
        }.not_to change { DB::GuestbookMessage.count }

        expect(result).to have_generated(NewGuestbookMessagePage)
        expect(form).to have_constraint_violation(:message, key: :not_enough_words)
        expect(flash.alert).to eq("guestbook_not_saved")
      end
    end
    context "the ip address has already been used" do

      it "indicates a server-side error and generates the new guestbook message page" do
        existing_message = create(:guestbook_message)

        form            = GuestbookMessageForm.new(params: {
          name: "Pat",
          message: "This website is amazing!",
        })
        flash           = empty_flash
        session         = empty_session
        rack_request_ip = existing_message.ip_address

        handler = described_class.new(
          form:,
          flash:,
          session:,
          rack_request_ip:
        )
        result = nil
        expect {
          result = handler.handle
        }.not_to change { DB::GuestbookMessage.count }

        expect(result).to have_generated(NewGuestbookMessagePage)
        expect(form).to have_constraint_violation(:name, key: :already_posted)
        expect(flash.alert).to eq("guestbook_not_saved")
      end
    end
    context "no constraint violations, unused ip address" do
      it "saves the message and redirects back to the guestbook page" do
        form            = GuestbookMessageForm.new(params: {
          name: "Pat",
          message: "This website is amazing!",
        })
        flash           = empty_flash
        session         = empty_session
        rack_request_ip = Faker::Internet.ip_v4_address

        handler = described_class.new(
          form:,
          flash:,
          session:,
          rack_request_ip:
        )
        result = nil
        expect {
          result = handler.handle
        }.to change { DB::GuestbookMessage.count }.by(1)

        message = DB::GuestbookMessage.order(Sequel.desc(:created_at)).first

        expect(message.name).to       eq("Pat")
        expect(message.message).to    eq("This website is amazing!")
        expect(message.ip_address).to eq(rack_request_ip)

        expect(result).to       have_redirected_to(GuestbookPage,
                                                   anchor: message.external_id)
        expect(form).not_to     have_constraint_violation(:name,
                                                          key: :already_posted)
        expect(flash.notice).to eq("guestbook_saved")

      end
    end
  end
end
