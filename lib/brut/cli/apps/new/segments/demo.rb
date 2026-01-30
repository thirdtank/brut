# Additional classes and configuration for a new Brut
# app that provides a more demonstration of the features.
class Brut::CLI::Apps::New::Segments::Demo < Brut::CLI::Apps::New::Base

  def self.friendly_name = "Demo features and files"
  def self.segment_name = "demo_features"

  def initialize(app_name:, options:, versions:, current_dir:, templates_dir:)
    @project_root  = current_dir / app_name
    @templates_dir = templates_dir / "segments" / "Demo"
    @erb_binding   = ErbBindingDelegate.new(options:, app_name:, versions:)
  end

  def <=>(other)
    if self.class == other.class
      0
    else
      1
    end
  end

  def add!
    operations = copy_files(@templates_dir, @project_root) + 
                 other_operations(@project_root)

    operations.each do |operation|
      operation.call
    end
  end

private

  def other_operations(project_root)
    [
      Brut::CLI::Apps::New::Ops::AddI18nMessage.new(
        project_root: project_root,
        hash: {
          en: {
            cv: {
              ss: {
                not_enough_words: "%{field} does not have enough words",
                already_posted: "You've already posted a message. Thanks for that!",
              },
            },
            pages: {
              "NewGuestbookMessagePage": {
                title: "New guestbook message page",
              },
              "GuestbookPage": {
                title: "Guestbook page",
              },
            },
            guestbook_not_saved: "Your guestbook message was not saved",
            guestbook_saved: "Thanks for writing!",
          },
        }
      ),
      Brut::CLI::Apps::New::Ops::InsertRoute.new(
        project_root: project_root,
        code: %{page "/guestbook"},
      ),
      Brut::CLI::Apps::New::Ops::InsertRoute.new(
        project_root: project_root,
        code: %{form "/guestbook_message"},
      ),
      Brut::CLI::Apps::New::Ops::InsertRoute.new(
        project_root: project_root,
        code: %{page "/new_guestbook_message"},
      ),
      Brut::CLI::Apps::New::Ops::InsertCodeInMethod.new(
        file: project_root / "app" / "src" / "back_end" / "data_models" / "seed" / "seed_data.rb",
        class_name: "SeedData",
        method_name: "seed!",
        code: %{
10.times do
  create(:guestbook_message, created_at: Date.today - rand(1..100))
end
}
      ),
      Brut::CLI::Apps::New::Ops::AddCSSImport.new(
        project_root: project_root,
        import: "constraint-violations.css"
      ),
      Brut::CLI::Apps::New::Ops::AddCSSImport.new(
        project_root: project_root,
        import: "fonts.css"
      ),
      Brut::CLI::Apps::New::Ops::InsertCodeInMethod.new(
        file: project_root / "app" / "src" / "front_end" / "pages"/ "home_page.rb",
        class_name: "HomePage",
        method_name: "page_template",
        where: :start,
        code: %{
div(class: "w-50 mh-auto mt-4") do
  a(href: NewGuestbookMessagePage.routing,
    class: "db f-3 ff-sans blue-400 fw-bold tc"
  ) do
    "Sign The Guestbook!"
  end
end
}
      ),
      Brut::CLI::Apps::New::Ops::AddMethod.new(
        file: project_root / "app" / "src" / "front_end" / "support" / "app_session.rb",
        class_name: "AppSession",
        code: %{def signed_guestbook? = !!self.guestbook_message},
      ),
      Brut::CLI::Apps::New::Ops::AddMethod.new(
        file: project_root / "app" / "src" / "front_end" / "support" / "app_session.rb",
        class_name: "AppSession",
        code: %{
def guestbook_message
  DB::GuestbookMessage.find(
    external_id: self[:guestbook_message_external_id]
  )
end
}
      ),
      Brut::CLI::Apps::New::Ops::AddMethod.new(
        file: project_root / "app" / "src" / "front_end" / "support" / "app_session.rb",
        class_name: "AppSession",
        code: %{
def signed_guestbook(guestbook_message)
  self[:guestbook_message_external_id] = guestbook_message.external_id
end
}
      ),
    ]
  end
end
