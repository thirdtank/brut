class GuestbookMessageHandler < AppHandler
  def initialize(form:, flash:, rack_request_ip:, session:)
    @form            = form
    @flash           = flash
    @rack_request_ip = rack_request_ip
    @session         = session
  end
  def handle
    # If client-side constraint violation checking was skipped,
    # but there ARE such violations, the form will be able to check
    # that server-side and return true for #constraint_violations?
    if @form.valid?
      save_message
    end

    if @form.constraint_violations?
      @flash.alert = :guestbook_not_saved
      return NewGuestbookMessagePage.new(form: @form,
                                         session: @session)
    else
      @flash.notice = :guestbook_saved
      redirect_to(
        GuestbookPage,
        anchor: @session.guestbook_message&.external_id
      )
    end
  end

private

  def save_message
    # While we don't recommend business logic be placed
    # inside handlers, we're leaving it here to avoid
    # anchoring you on any particular way of managing
    # the logic in your app.
    if @form.message.split(/\s+/).length < 2
      @form.server_side_constraint_violation(
        input_name: "message",
        key: :not_enough_words
      )
    else
      if DB::GuestbookMessage.find(ip_address: @rack_request_ip)
        @form.server_side_constraint_violation(
          input_name: "name",
          key: :already_posted
        )
      else
        begin
          guestbook_message = DB::GuestbookMessage.create(
            name: @form.name,
            message: @form.message,
            ip_address: @rack_request_ip,
          )
          @session.signed_guestbook(guestbook_message)
        rescue Sequel::UniqueConstraintViolation => ex
          @form.server_side_constraint_violation(
            input_name: "name",
            key: :already_posted
          )
        end
      end
    end
  end
end
