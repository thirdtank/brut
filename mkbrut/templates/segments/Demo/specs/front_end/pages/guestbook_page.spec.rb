require "spec_helper"

RSpec.describe GuestbookPage do
  it "shows current guestbook messages" do
    messages = 5.times.map {
      create(:guestbook_message)
    }
    confidence_check { expect(DB::GuestbookMessage.all.length).to eq(5) }

    result = generate_and_parse(self.described_class.new(session: empty_session))

    message_elements = result.css("div:has(> blockquote)")
    expect(message_elements.length).to eq(5)
    messages.each do |message|
      element = message_elements.select {
        it.css("blockquote").text.strip == message.message
      }
      expect(element.size).to eq(1),
        "Found #{element.size} blockquotes for message #{message.external_id}, instead of exactly 1" 
      expect(element[0].css("p").text).to include(message.name)
    end
  end
  context "when you've signed the guestbook" do
    it "shows a link to view your message and not a link to make one" do
      message = create(:guestbook_message)
      session = empty_session

      session.signed_guestbook(message)

      result = generate_and_parse(self.described_class.new(session:))

      add_link = result.e("a[href='#{NewGuestbookMessagePage.routing}']")
      expect(add_link).to eq(nil)

      view_link = result.e("a[href='##{message.external_id}']")
      expect(view_link).not_to eq(nil)
    end
  end
  context "when you have not signed the guestbook" do
    it "shows a link to view your message and not a link to make one" do
      message = create(:guestbook_message)

      result = generate_and_parse(self.described_class.new(session: empty_session))

      add_link = result.e("a[href='#{NewGuestbookMessagePage.routing}']")
      expect(add_link).not_to eq(nil)

      view_link = result.e("a[href='##{message.external_id}']")
      expect(view_link).to eq(nil)
    end
  end
end
