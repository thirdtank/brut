Sequel.migration do
  up do
    create_table :guestbook_messages,
      comment: "Messages people have left in the guestbook",
      external_id: true do 

      column :name, :text
      column :message, :text
      column :ip_address, :inet

      key [ :ip_address ]
    end
  end
end
