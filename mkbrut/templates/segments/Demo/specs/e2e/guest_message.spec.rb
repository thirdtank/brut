require "spec_helper"

RSpec.describe "You can leave a guestbook message" do
  it "accepts your message after validation, then shows it with the others" do
    page.goto(HomePage.routing)

    link = page.locator("a[href='#{NewGuestbookMessagePage.routing}']")

    link.click

    expect(page).to be_page_for(NewGuestbookMessagePage)

    button = page.locator("form button")

    button.click
    expect(page).to be_page_for(NewGuestbookMessagePage)

    name_error_message    = page.locator("brut-cv-messages[input-name='name']")
    message_error_message = page.locator("brut-cv-messages[input-name='message']")

    this_field = t("cv.this_field")

    expect(name_error_message).to    have_text(
      t("cv.cs.valueMissing", field: this_field)
    )
    expect(message_error_message).to have_text(
      t("cv.cs.valueMissing", field: this_field)
    )

    name_field    = page.locator("form input[name='name']")
    message_field = page.locator("form textarea[name='message']")

    name_field.fill("Pat")
    message_field.fill("FIRSTPOST!")

    button.click
    expect(page).to be_page_for(NewGuestbookMessagePage)
    
    flash = page.locator("[role='alert']")
    expect(flash).to have_text(t(:guestbook_not_saved))
    expect(message_error_message).to have_text(
      t("cv.ss.not_enough_words", field: this_field)
    )

    message_field.fill("OK, fine, this site is awesome!")
    button.click

    expect(page).to be_page_for(GuestbookPage)

    quotes = page.locator("blockquote")
    expect(quotes).to have_text("OK, fine, this site is awesome!")

  end
end
