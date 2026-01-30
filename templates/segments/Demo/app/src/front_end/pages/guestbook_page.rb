class GuestbookPage < AppPage

  def initialize(session:)
    @session = session
  end

  def page_template
    div(class: "flex flex-column items-center ff-sans") do
      article(class: "w-50 pv-3 bt bc-gray-700", id: "guestbook") do
        h2(class: "ff-sans ma-0 lh-title f-4 tc") do
          "Check out the Guestbook!"
        end
        if !@session.signed_guestbook?
          a(
            href: NewGuestbookMessagePage.routing,
            class: "db tc mv-3 f-2 fw-5 blue-300"
          ) do
            "Sign it, yourself!"
          end
        else
          a(
            href: "##{@session.guestbook_message.external_id}",
            class: "db tc mv-3 f-2 fw-5 blue-300"
          ) do
            "Check out your message"
          end

        end
        DB::GuestbookMessage.order(
          Sequel.function(:random)
        ).each_with_index do |message,index|
          render(
            GuestbookPage::MessageComponent.new(
              message:,
              index:,
              current_visitor_message: message == @session.guestbook_message
            )
          )
        end
      end
    end
  end
end
