class GuestbookMessageForm < AppForm
  input :name, minlength: 2
  input :message, minlength: 10
end
