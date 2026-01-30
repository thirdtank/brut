class NewGuestbookMessagePage < AppPage
  def initialize(form: nil, session:)
    @form    = form || GuestbookMessageForm.new
    @session = session
  end

  def before_generate
    if @session.signed_guestbook?
      redirect_to(GuestbookPage)
    end
  end

  def page_template
    div(class: "flex flex-column items-center ff-sans") do
      render global_component(FlashComponent)
      div(class: "w-50 mv-5") do
        brut_form(class: "w-100") do
          FormTag(for: @form, class: "flex flex-column gap-3 items-end") do
            h1(class: "ff-sans ma-0 lh-title f-5 self-start flex items-center gap-3") do
              img(src: "/static/images/icon.png", class: "w-5")
              span { "Sign The Guestbook" }
            end
            label(class: "flex flex-column gap-1 w-100") do
              Inputs::InputTag(
                form: @form,
                input_name: "name",
                placeholder: "e.g. Pat",
                class: "f-3 pa-2 inset-shadow-1 br-2",
                "data-1p-ignore": true
              )
              div(class: "flex items-start gap-3") do
                span { "Your Message" }
                ConstraintViolations(
                  form: @form,
                  input_name: "name"
                )
              end

            end
            label(class: "flex flex-column gap-1 w-100") do
              Inputs::TextareaTag(
                form: @form,
                input_name: "message",
                placeholder: "e.g. What a great site!",
                rows: 6,
                class: "f-3 pa-2 inset-shadow-1 br-2"
              )
              div(class: "flex items-start gap-3") do
                span { "Your Message" }
                ConstraintViolations(
                  form: @form,
                  input_name: "message"
                )
              end
            end
            button(class: "bg-green-900 green-300 ph-5 pv-3 f-3 ba bc-green-600 br-pill shadow-1 pointer") do
              "Sign!"
            end
          end
        end
      end
    end
  end
end
