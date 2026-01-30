class GuestbookPage::MessageComponent < AppComponent
  def initialize(message:, index:, current_visitor_message: false)
    @message = message
    @current_visitor_message = current_visitor_message
    @background_color = [
      "bg-gray-800",
      "bg-blue-800",
      "bg-green-800",
      "bg-yellow-800",
    ][index % 4]
  end

  def view_template
    div_classes = [
      "measure",
      "mh-auto",
      "pa-3",
      "br-4",
      "br-tr-0",
      "br-bl-0",
      "mt-3",
      @background_color,
    ]
    border_class = if @current_visitor_message
                     div_classes << "ba" << "bc-gray-600" << "bw-2"
                   else
                     div_classes << "bn"
                   end
    div(class: div_classes, id: @message.external_id) do
      blockquote(class: "ff-cursive p mh-auto i f-4") do
        @message.message
      end
      p(class: "p mh-auto tr f-2") do
        plain("—")
        plain(@message.name)
        plain(" on ")
        TimeTag(date: @message.created_at, format: :date, class: "gray-400 f-1 ttu")
      end
    end
  end
end
