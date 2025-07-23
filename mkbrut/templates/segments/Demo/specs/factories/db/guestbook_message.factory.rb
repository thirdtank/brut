FactoryBot.define do
  factory :guestbook_message, class: "DB::GuestbookMessage" do
    name       { Faker::Name.name }
    message    { Faker::Lorem.paragraph }
    ip_address { Faker::Internet.unique.ip_v4_address }
  end
end
